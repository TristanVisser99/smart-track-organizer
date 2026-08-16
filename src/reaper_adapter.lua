local core = require("smart_track_organizer_core")
local palettes = require("palettes")

local adapter = {}

adapter.EXT_NAMESPACE = "SmartTrackOrganizer"
adapter.GENERATED_FOLDER_KEY = "generated_folder"
adapter.CATEGORY_KEY = "category"
adapter.PREFS_SECTION = "SmartTrackOrganizer_Config"

---Load persistent user options from REAPER's ExtState
---@param reaper_api table
---@return table
function adapter.load_options(reaper_api)
  local opts = {
    create_folders = true,
    prefix_names = true,
    sort_tracks = true,
    selected_only = false,
    palette = palettes.DEFAULT
  }

  if reaper_api and reaper_api.HasExtState and reaper_api.HasExtState(adapter.PREFS_SECTION, "saved") then
    local get_bool = function(key, default)
      local val = reaper_api.GetExtState(adapter.PREFS_SECTION, key)
      if val == "1" then return true end
      if val == "0" then return false end
      return default
    end

    opts.create_folders = get_bool("create_folders", opts.create_folders)
    opts.prefix_names = get_bool("prefix_names", opts.prefix_names)
    opts.sort_tracks = get_bool("sort_tracks", opts.sort_tracks)
    opts.selected_only = get_bool("selected_only", opts.selected_only)
    local saved_sort = reaper_api.GetExtState(adapter.PREFS_SECTION, "sort_mode")
    if saved_sort and saved_sort ~= "" then
      opts.sort_mode = saved_sort
    else
      opts.sort_mode = "mix"
    end
    local saved_palette = reaper_api.GetExtState(adapter.PREFS_SECTION, "palette")
    if saved_palette and saved_palette ~= "" and palettes.themes[saved_palette] then
      opts.palette = saved_palette
    end
  else
    opts.sort_mode = "mix"
  end

  return opts
end

---Save user options to REAPER's ExtState so they persist across sessions
---@param opts table
---@param reaper_api table
function adapter.save_options(opts, reaper_api)
  if not reaper_api or not reaper_api.SetExtState then
    return
  end
  local set_bool = function(key, val)
    reaper_api.SetExtState(adapter.PREFS_SECTION, key, val and "1" or "0", true)
  end

  set_bool("create_folders", opts.create_folders)
  set_bool("prefix_names", opts.prefix_names)
  set_bool("sort_tracks", opts.sort_tracks)
  set_bool("selected_only", opts.selected_only)
  reaper_api.SetExtState(adapter.PREFS_SECTION, "sort_mode", tostring(opts.sort_mode or "mix"), true)
  reaper_api.SetExtState(adapter.PREFS_SECTION, "palette", tostring(opts.palette or palettes.DEFAULT), true)
  reaper_api.SetExtState(adapter.PREFS_SECTION, "saved", "1", true)
end



function adapter.get_track_name(track, reaper_api)
  local _, name = reaper_api.GetTrackName(track)
  return name or ""
end

function adapter.get_track_fx_names(track, reaper_api)
  if not reaper_api or not reaper_api.TrackFX_GetCount then
    return {}
  end
  local fx_count = reaper_api.TrackFX_GetCount(track)
  local list = {}
  for i = 0, fx_count - 1 do
    local _, fx_name = reaper_api.TrackFX_GetFXName(track, i, "")
    if fx_name and fx_name ~= "" then
      list[#list + 1] = fx_name
    end
  end
  return list
end

function adapter.get_ext(track, key, reaper_api)
  local _, value = reaper_api.GetSetMediaTrackInfo_String(track, "P_EXT:" .. adapter.EXT_NAMESPACE .. ":" .. key, "", false)
  return value or ""
end

function adapter.set_ext(track, key, value, reaper_api)
  reaper_api.GetSetMediaTrackInfo_String(track, "P_EXT:" .. adapter.EXT_NAMESPACE .. ":" .. key, tostring(value or ""), true)
end

function adapter.is_generated_folder(track, reaper_api)
  return adapter.get_ext(track, adapter.GENERATED_FOLDER_KEY, reaper_api) == "1" or adapter.get_track_name(track, reaper_api):match("^STO %- ") ~= nil
end

function adapter.collect_tracks(reaper_api)
  local tracks = {}
  for index = 0, reaper_api.CountTracks(0) - 1 do
    local track = reaper_api.GetTrack(0, index)
    tracks[#tracks + 1] = {
      id = tostring(track),
      ptr = track,
      name = adapter.get_track_name(track, reaper_api),
      fx_names = adapter.get_track_fx_names(track, reaper_api),
      selected = reaper_api.IsTrackSelected(track),
      generated_folder = adapter.is_generated_folder(track, reaper_api),
      original_index = index
    }
  end
  return tracks
end

function adapter.delete_generated_folders(reaper_api)
  for index = reaper_api.CountTracks(0) - 1, 0, -1 do
    local track = reaper_api.GetTrack(0, index)
    if adapter.is_generated_folder(track, reaper_api) then
      reaper_api.SetMediaTrackInfo_Value(track, "I_FOLDERDEPTH", 0)
      reaper_api.DeleteTrack(track)
    end
  end
end

function adapter.find_live_track_by_id(id, reaper_api)
  for index = 0, reaper_api.CountTracks(0) - 1 do
    local track = reaper_api.GetTrack(0, index)
    if tostring(track) == id then
      return track
    end
  end
  return nil
end

function adapter.execute_plan(plan, reaper_api)
  reaper_api.Undo_BeginBlock()
  reaper_api.PreventUIRefresh(1)

  adapter.delete_generated_folders(reaper_api)

  -- Apply names and colors
  for _, item in ipairs(plan.tracks) do
    local track = item.track.ptr or adapter.find_live_track_by_id(item.id, reaper_api)
    if track then
      reaper_api.GetSetMediaTrackInfo_String(track, "P_NAME", item.new_name, true)
      reaper_api.SetTrackColor(track, palettes.to_native(item.color, reaper_api))
      adapter.set_ext(track, adapter.CATEGORY_KEY, item.category_key, reaper_api)
    end
  end

  -- Reorder tracks
  if plan.options.sort_tracks ~= false then
    for _, item in ipairs(plan.tracks) do
      local track = item.track.ptr or adapter.find_live_track_by_id(item.id, reaper_api)
      if track then
        reaper_api.SetOnlyTrackSelected(track)
        reaper_api.ReorderSelectedTracks(item.new_index - 1, 0)
      end
    end
  end

  -- Create folder groups
  if plan.options.create_folders then
    for index = 0, reaper_api.CountTracks(0) - 1 do
      local track = reaper_api.GetTrack(0, index)
      if not adapter.is_generated_folder(track, reaper_api) then
        reaper_api.SetMediaTrackInfo_Value(track, "I_FOLDERDEPTH", 0)
      end
    end

    for _, insertion in ipairs(core.folder_insertions(plan)) do
      reaper_api.InsertTrackAtIndex(insertion.insert_at_zero, true)
      local folder = reaper_api.GetTrack(0, insertion.folder_index_zero)
      reaper_api.GetSetMediaTrackInfo_String(folder, "P_NAME", "STO - " .. insertion.label, true)
      reaper_api.SetTrackColor(folder, palettes.to_native(insertion.color, reaper_api))
      reaper_api.SetMediaTrackInfo_Value(folder, "I_FOLDERDEPTH", 1)
      adapter.set_ext(folder, adapter.GENERATED_FOLDER_KEY, "1", reaper_api)
      adapter.set_ext(folder, adapter.CATEGORY_KEY, insertion.key, reaper_api)

      local last_child = reaper_api.GetTrack(0, insertion.last_child_index_zero)
      if last_child then
        reaper_api.SetMediaTrackInfo_Value(last_child, "I_FOLDERDEPTH", -1)
      end
    end
  end

  reaper_api.PreventUIRefresh(-1)
  if reaper_api.TrackList_AdjustWindows then
    reaper_api.TrackList_AdjustWindows(false)
  end
  if reaper_api.UpdateArrange then
    reaper_api.UpdateArrange()
  end
  reaper_api.Undo_EndBlock("Smart Track Organizer", -1)
end

return adapter
