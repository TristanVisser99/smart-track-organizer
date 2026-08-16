package.path = "src/?.lua;" .. package.path

local ui_state = require("ui_state")

local function assert_eq(actual, expected, msg)
  if actual ~= expected then
    error(string.format("%s: expected '%s', got '%s'", msg or "Assertion failed", tostring(expected), tostring(actual)))
  end
end

local mock_reaper = {
  CountTracks = function(proj) return 4 end,
  GetTrack = function(proj, idx)
    local names = { [0] = "Kick In", [1] = "Snare Top", [2] = "Lead Vox", [3] = "Bass DI" }
    return { idx = idx, name = names[idx] or "Track", selected = true, color = 0, folder_depth = 0, ext = {} }
  end,
  GetTrackName = function(track)
    return true, track.name
  end,
  IsTrackSelected = function(track)
    return track.selected
  end,
  GetSetMediaTrackInfo_String = function(track, field, val, set)
    if field == "P_NAME" then
      if set then track.name = val end
      return true, track.name
    end
    return false, ""
  end,
  GetMediaTrackInfo_Value = function(track, field)
    if field == "IP_TRACKNUMBER" then return track.idx + 1 end
    if field == "I_FOLDERDEPTH" then return 0 end
    if field == "I_SELECTED" then return 1 end
    if field == "I_CUSTOMCOLOR" then return 0 end
    return 0
  end,
  GetExtState = function(section, key) return "" end,
  SetExtState = function(section, key, val, persist) end
}

local function test_ui_state_initialization()
  local state = ui_state.create(mock_reaper)
  assert_eq(state.total_count, 4, "Tracks count matches mock reaper")
  assert_eq(state.active_count, 4, "All tracks active initially")
  assert_eq(#state.display_items, 4, "Display items match total tracks")
  print("ok - ui_state_initialization")
end

local function test_ui_state_filtering()
  local state = ui_state.create(mock_reaper)
  state:set_filter("vox")
  assert_eq(#state.display_items, 1, "Filter matches exactly 1 track (Lead Vox)")
  assert_eq(state.display_items[1].raw_track.name, "Lead Vox", "Filtered item is Lead Vox")

  state:set_filter("")
  assert_eq(#state.display_items, 4, "Clearing filter restores all 4 items")
  print("ok - ui_state_filtering")
end

local function test_ui_state_selection_and_options()
  local state = ui_state.create(mock_reaper)
  state:set_all_selected(false)
  assert_eq(state.active_count, 0, "Deselecting all makes active count 0")

  local raw_tracks = state.raw_tracks
  local first_id = raw_tracks[1].id
  state:set_track_selected(first_id, true)
  assert_eq(state.active_count, 1, "Selecting first track makes active count 1")

  state:update_options{ palette = "neon", prefix_names = false }
  assert_eq(state.options.palette, "neon", "Palette updated to neon")
  assert_eq(state.options.prefix_names, false, "Prefix names disabled")
  print("ok - ui_state_selection_and_options")
end

test_ui_state_initialization()
test_ui_state_filtering()
test_ui_state_selection_and_options()
print("All ui_state tests passed.")
