-- @description Smart Track Organizer
-- @author Codex
-- @version 1.0.0
-- @about
--   Automatically classifies, colors, renames, sorts, and visually groups REAPER tracks.
--   Import this Lua file into REAPER's Action List and run it from the Actions menu.

local script_file = ({ reaper.get_action_context() })[2] or ""
local script_path = script_file:match("^(.*)[/\\]") or "."
package.path = script_path .. "/src/?.lua;" .. package.path

local core = require("smart_track_organizer_core")

local EXT_NAMESPACE = "SmartTrackOrganizer"
local GENERATED_FOLDER_KEY = "generated_folder"
local CATEGORY_KEY = "category"

local function color_to_native(rgb)
  local r = math.floor(rgb / 0x10000) % 0x100
  local g = math.floor(rgb / 0x100) % 0x100
  local b = rgb % 0x100
  return reaper.ColorToNative(r, g, b) + 0x1000000
end

local function get_track_name(track)
  local _, name = reaper.GetTrackName(track)
  return name or ""
end

local function get_ext(track, key)
  local _, value = reaper.GetSetMediaTrackInfo_String(track, "P_EXT:" .. EXT_NAMESPACE .. ":" .. key, "", false)
  return value or ""
end

local function set_ext(track, key, value)
  reaper.GetSetMediaTrackInfo_String(track, "P_EXT:" .. EXT_NAMESPACE .. ":" .. key, tostring(value or ""), true)
end

local function is_generated_folder(track)
  return get_ext(track, GENERATED_FOLDER_KEY) == "1" or get_track_name(track):match("^STO %- ") ~= nil
end

local function collect_tracks()
  local tracks = {}
  for index = 0, reaper.CountTracks(0) - 1 do
    local track = reaper.GetTrack(0, index)
    tracks[#tracks + 1] = {
      id = tostring(track),
      ptr = track,
      name = get_track_name(track),
      selected = reaper.IsTrackSelected(track),
      generated_folder = is_generated_folder(track),
      original_index = index
    }
  end
  return tracks
end

local function delete_generated_folders()
  for index = reaper.CountTracks(0) - 1, 0, -1 do
    local track = reaper.GetTrack(0, index)
    if is_generated_folder(track) then
      reaper.SetMediaTrackInfo_Value(track, "I_FOLDERDEPTH", 0)
      reaper.DeleteTrack(track)
    end
  end
end

local function prompt_options()
  local ok, values = reaper.GetUserInputs(
    "Smart Track Organizer",
    4,
    "Scope: all or selected,Create folder groups? yes/no,Prefix renamed tracks? yes/no,Dry run? yes/no",
    "all,yes,yes,no"
  )
  if not ok then
    return nil
  end

  local fields = {}
  for field in (values .. ","):gmatch("([^,]*),") do
    fields[#fields + 1] = field:lower():gsub("^%s+", ""):gsub("%s+$", "")
  end

  return {
    selected_only = fields[1] == "selected",
    create_folders = fields[2] ~= "no",
    prefix_names = fields[3] ~= "no",
    dry_run = fields[4] == "yes"
  }
end

local function show_plan(plan)
  local lines = {
    "Smart Track Organizer dry run",
    "",
    core.summarize_plan(plan),
    ""
  }
  for _, item in ipairs(plan.tracks) do
    lines[#lines + 1] = string.format(
      "%02d. %-14s %s -> %s",
      item.new_index,
      item.category_label,
      item.original_name,
      item.new_name
    )
  end
  reaper.ShowMessageBox(table.concat(lines, "\n"), "Smart Track Organizer", 0)
end

local function find_live_track_by_id(id)
  for index = 0, reaper.CountTracks(0) - 1 do
    local track = reaper.GetTrack(0, index)
    if tostring(track) == id then
      return track
    end
  end
  return nil
end

local function apply_names_colors(plan)
  for _, item in ipairs(plan.tracks) do
    local track = item.track.ptr or find_live_track_by_id(item.id)
    if track then
      reaper.GetSetMediaTrackInfo_String(track, "P_NAME", item.new_name, true)
      reaper.SetTrackColor(track, color_to_native(item.color))
      set_ext(track, CATEGORY_KEY, item.category_key)
    end
  end
end

local function reorder_tracks(plan)
  for _, item in ipairs(plan.tracks) do
    local track = item.track.ptr or find_live_track_by_id(item.id)
    if track then
      reaper.SetOnlyTrackSelected(track)
      reaper.ReorderSelectedTracks(item.new_index - 1, 0)
    end
  end
end

local function create_folder_groups(plan)
  if not plan.options.create_folders then
    return
  end

  for index = 0, reaper.CountTracks(0) - 1 do
    local track = reaper.GetTrack(0, index)
    if not is_generated_folder(track) then
      reaper.SetMediaTrackInfo_Value(track, "I_FOLDERDEPTH", 0)
    end
  end

  for _, insertion in ipairs(core.folder_insertions(plan)) do
    reaper.InsertTrackAtIndex(insertion.insert_at_zero, true)
    local folder = reaper.GetTrack(0, insertion.folder_index_zero)
    reaper.GetSetMediaTrackInfo_String(folder, "P_NAME", "STO - " .. insertion.label, true)
    reaper.SetTrackColor(folder, color_to_native(insertion.color))
    reaper.SetMediaTrackInfo_Value(folder, "I_FOLDERDEPTH", 1)
    set_ext(folder, GENERATED_FOLDER_KEY, "1")
    set_ext(folder, CATEGORY_KEY, insertion.key)

    local last_child = reaper.GetTrack(0, insertion.last_child_index_zero)
    if last_child then
      reaper.SetMediaTrackInfo_Value(last_child, "I_FOLDERDEPTH", -1)
    end
  end
end

local function main()
  if not reaper or not reaper.CountTracks then
    error("This script must be run inside REAPER.")
  end

  local options = prompt_options()
  if not options then
    return
  end

  local tracks = collect_tracks()
  local plan = core.build_plan(tracks, options)
  if #plan.tracks == 0 then
    reaper.ShowMessageBox("No tracks found for the selected scope.", "Smart Track Organizer", 0)
    return
  end

  if options.dry_run then
    show_plan(plan)
    return
  end

  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)
  delete_generated_folders()
  apply_names_colors(plan)
  reorder_tracks(plan)
  create_folder_groups(plan)
  reaper.PreventUIRefresh(-1)
  reaper.TrackList_AdjustWindows(false)
  reaper.UpdateArrange()
  reaper.Undo_EndBlock("Smart Track Organizer", -1)

  reaper.ShowMessageBox(core.summarize_plan(plan), "Smart Track Organizer complete", 0)
end

main()
