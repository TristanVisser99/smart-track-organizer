local function assert_equal(actual, expected, message)
  if actual ~= expected then
    error(string.format("%s\nexpected: %s\nactual:   %s", message or "assertion failed", tostring(expected), tostring(actual)), 2)
  end
end

local function assert_true(value, message)
  if not value then
    error(message or "expected value to be true", 2)
  end
end

local function new_track(name, selected)
  return {
    name = name,
    selected = selected ~= false,
    color = 0,
    folder_depth = 0,
    ext = {}
  }
end

local function make_reaper_mock(input, tracks)
  local mock = {
    tracks = tracks,
    messages = {},
    undo_started = false,
    undo_ended = false,
    refresh_depth = 0,
    arranged = false,
    extstate = {}
  }

  function mock.HasExtState(section, key)
    return mock.extstate[section .. ":" .. key] ~= nil
  end

  function mock.GetExtState(section, key)
    return mock.extstate[section .. ":" .. key] or ""
  end

  function mock.SetExtState(section, key, val, persist)
    mock.extstate[section .. ":" .. key] = tostring(val)
  end


  function mock.get_action_context()
    return nil, "./Smart Track Organizer.lua"
  end

  function mock.CountTracks()
    return #mock.tracks
  end

  function mock.GetTrack(_, index)
    return mock.tracks[index + 1]
  end

  function mock.GetTrackName(track)
    return true, track.name
  end

  function mock.IsTrackSelected(track)
    return track.selected
  end

  function mock.GetSetMediaTrackInfo_String(track, key, value, set_new_value)
    if key == "P_NAME" then
      if set_new_value then
        track.name = value
      end
      return true, track.name
    end

    local ext_key = key:match("^P_EXT:(.+)$")
    if ext_key then
      if set_new_value then
        track.ext[ext_key] = value
      end
      return true, track.ext[ext_key] or ""
    end

    return false, ""
  end

  function mock.SetTrackColor(track, color)
    track.color = color
  end

  function mock.ColorToNative(r, g, b)
    return r * 0x10000 + g * 0x100 + b
  end

  function mock.SetMediaTrackInfo_Value(track, key, value)
    if key == "I_FOLDERDEPTH" then
      track.folder_depth = value
    end
  end

  function mock.GetUserInputs()
    if input == false then
      return false, ""
    end
    return true, input
  end

  function mock.ShowMessageBox(message, title)
    mock.messages[#mock.messages + 1] = { message = message, title = title }
    return 0
  end

  function mock.Undo_BeginBlock()
    mock.undo_started = true
  end

  function mock.Undo_EndBlock()
    mock.undo_ended = true
  end

  function mock.PreventUIRefresh(delta)
    mock.refresh_depth = mock.refresh_depth + delta
  end

  function mock.SetOnlyTrackSelected(track)
    for _, candidate in ipairs(mock.tracks) do
      candidate.selected = candidate == track
    end
  end

  function mock.ReorderSelectedTracks(destination_index)
    local moving
    local old_index
    for index, candidate in ipairs(mock.tracks) do
      if candidate.selected then
        moving = candidate
        old_index = index
        break
      end
    end
    if not moving then
      return
    end

    table.remove(mock.tracks, old_index)
    local destination = math.max(1, math.min(destination_index + 1, #mock.tracks + 1))
    table.insert(mock.tracks, destination, moving)
  end

  function mock.InsertTrackAtIndex(index)
    table.insert(mock.tracks, index + 1, new_track(""))
  end

  function mock.DeleteTrack(track)
    for index, candidate in ipairs(mock.tracks) do
      if candidate == track then
        table.remove(mock.tracks, index)
        return
      end
    end
  end

  function mock.TrackList_AdjustWindows()
  end

  function mock.UpdateArrange()
    mock.arranged = true
  end

  return mock
end

local function run_script(input, tracks)
  _G.reaper = make_reaper_mock(input, tracks)
  dofile("Smart Track Organizer.lua")
  local mock = _G.reaper
  _G.reaper = nil
  return mock
end

local tests = {}

function tests.applies_sort_rename_color_and_folder_groups()
  local mock = run_script("all,yes,yes,no", {
    new_track("Lead Vocal"),
    new_track("Kick"),
    new_track("Bass DI")
  })

  assert_equal(#mock.tracks, 6)
  assert_equal(mock.tracks[1].name, "STO - Drums")
  assert_equal(mock.tracks[1].folder_depth, 1)
  assert_equal(mock.tracks[2].name, "DRM - Kick")
  assert_equal(mock.tracks[2].folder_depth, -1)
  assert_equal(mock.tracks[3].name, "STO - Bass")
  assert_equal(mock.tracks[4].name, "BAS - Bass DI")
  assert_equal(mock.tracks[5].name, "STO - Vocals")
  assert_equal(mock.tracks[6].name, "VOX - Lead Vocal")
  assert_true(mock.tracks[2].color ~= 0, "organized child tracks should be colored")
  assert_true(mock.tracks[1].ext["SmartTrackOrganizer:generated_folder"] == "1", "folder should be tagged as generated")
  assert_true(mock.undo_started and mock.undo_ended, "changes should be wrapped in an undo block")
  assert_equal(mock.refresh_depth, 0, "UI refresh calls should be balanced")
  assert_true(mock.arranged, "arrange view should be updated")
end

function tests.cancelled_prompt_does_not_mutate_project()
  local mock = run_script(false, {
    new_track("Lead Vocal"),
    new_track("Kick")
  })

  assert_equal(#mock.tracks, 2)
  assert_equal(mock.tracks[1].name, "Lead Vocal")
  assert_equal(mock.tracks[2].name, "Kick")
  assert_true(not mock.undo_started, "cancel should not open an undo block")
  assert_equal(#mock.messages, 0)
end

function tests.dry_run_previews_without_mutating()
  local mock = run_script("all,yes,yes,yes", {
    new_track("Lead Vocal"),
    new_track("Kick")
  })

  assert_equal(#mock.tracks, 2)
  assert_equal(mock.tracks[1].name, "Lead Vocal")
  assert_equal(mock.tracks[2].name, "Kick")
  assert_equal(#mock.messages, 1)
  assert_true(mock.messages[1].message:find("Smart Track Organizer dry run", 1, true) ~= nil)
  assert_true(not mock.undo_started, "dry run should not open an undo block")
end

function tests.existing_generated_folders_are_replaced_not_nested()
  local old_folder = new_track("STO - Drums")
  old_folder.folder_depth = 1
  old_folder.ext["SmartTrackOrganizer:generated_folder"] = "1"

  local old_child = new_track("DRM - Kick")
  old_child.folder_depth = -1

  local mock = run_script("all,yes,yes,no", {
    old_folder,
    old_child,
    new_track("VOX - Lead Vocal")
  })

  assert_equal(#mock.tracks, 4)
  assert_equal(mock.tracks[1].name, "STO - Drums")
  assert_equal(mock.tracks[2].name, "DRM - Kick")
  assert_equal(mock.tracks[3].name, "STO - Vocals")
  assert_equal(mock.tracks[4].name, "VOX - Lead Vocal")
  assert_true(mock.tracks[1] ~= old_folder, "old generated folder should be deleted and recreated")
end

function tests.no_folder_option_does_not_insert_folder_headers()
  local mock = run_script("all,no,yes,no", {
    new_track("Lead Vocal"),
    new_track("Kick"),
    new_track("Bass DI")
  })

  assert_equal(#mock.tracks, 3)
  assert_equal(mock.tracks[1].name, "DRM - Kick")
  assert_equal(mock.tracks[2].name, "BAS - Bass DI")
  assert_equal(mock.tracks[3].name, "VOX - Lead Vocal")
  assert_equal(mock.tracks[1].folder_depth, 0)
  assert_equal(mock.tracks[2].folder_depth, 0)
  assert_equal(mock.tracks[3].folder_depth, 0)
end

function tests.no_prefix_option_renames_without_category_codes()
  local mock = run_script("all,no,no,no", {
    new_track("lead_vocal"),
    new_track("kick_in")
  })

  assert_equal(mock.tracks[1].name, "Kick in")
  assert_equal(mock.tracks[2].name, "Lead Vocal")
end

function tests.selected_scope_leaves_unselected_tracks_out_of_the_plan()
  local mock = run_script("selected,no,yes,no", {
    new_track("Lead Vocal", true),
    new_track("Kick", false),
    new_track("Bass DI", true)
  })

  assert_equal(#mock.tracks, 3)
  assert_equal(mock.tracks[1].name, "BAS - Bass DI")
  assert_equal(mock.tracks[2].name, "VOX - Lead Vocal")
  assert_equal(mock.tracks[3].name, "Kick")
end

function tests.selected_scope_with_no_selected_tracks_is_noop()
  local mock = run_script("selected,yes,yes,no", {
    new_track("Lead Vocal", false),
    new_track("Kick", false)
  })

  assert_equal(#mock.tracks, 2)
  assert_equal(mock.tracks[1].name, "Lead Vocal")
  assert_equal(mock.tracks[2].name, "Kick")
  assert_true(not mock.undo_started, "empty selected scope should not open an undo block")
  assert_equal(mock.messages[1].message, "No tracks found for the selected scope.")
end

function tests.extstate_persists_user_preferences()
  local adapter = require("reaper_adapter")
  local mock = make_reaper_mock("", {})

  -- Test default options
  local opts = adapter.load_options(mock)
  assert_equal(opts.create_folders, true)
  assert_equal(opts.palette, "modern")

  -- Save custom options
  opts.create_folders = false
  opts.palette = "vintage"
  opts.prefix_names = false
  adapter.save_options(opts, mock)

  -- Reload and verify
  local reloaded = adapter.load_options(mock)
  assert_equal(reloaded.create_folders, false)
  assert_equal(reloaded.palette, "vintage")
  assert_equal(reloaded.prefix_names, false)
  assert_equal(reloaded.sort_tracks, true)
end


local function run()
  local names = {}
  for name in pairs(tests) do
    names[#names + 1] = name
  end
  table.sort(names)

  local passed = 0
  for _, name in ipairs(names) do
    tests[name]()
    passed = passed + 1
    io.write(string.format("ok - %s\n", name))
  end
  io.write(string.format("\n%d adapter tests passed\n", passed))
end

run()
