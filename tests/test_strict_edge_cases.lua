package.path = "src/?.lua;" .. package.path

local core = require("smart_track_organizer_core")
local lexicon = require("lexicon")
local palettes = require("palettes")

local function assert_eq(actual, expected, message)
  if actual ~= expected then
    error(string.format("%s: expected '%s', got '%s'", message or "Assertion failed", tostring(expected), tostring(actual)))
  end
end

-- 1. Test empty / nil / weird inputs
local function test_edge_case_inputs()
  assert_eq(core.clean_track_name(nil), "Untitled", "nil name becomes Untitled")
  assert_eq(core.clean_track_name(""), "Untitled", "empty string becomes Untitled")
  assert_eq(core.clean_track_name("    "), "Untitled", "whitespace only becomes Untitled")
  assert_eq(core.clean_track_name("track"), "Untitled", "'track' becomes Untitled")
  assert_eq(core.clean_track_name("Track 12"), "Untitled", "'Track 12' becomes Untitled")
  assert_eq(core.clean_track_name("---___..."), "Untitled", "only symbols becomes Untitled")

  local nil_plan = core.build_plan(nil)
  assert_eq(#nil_plan.tracks, 0, "nil tracks table yields 0 planned tracks")

  local empty_plan = core.build_plan({})
  assert_eq(#empty_plan.tracks, 0, "empty tracks table yields 0 planned tracks")
  print("ok - edge_case_inputs")
end

-- 2. Test complex stem naming strings with special symbols and multiple numbers
local function test_complex_stem_names()
  -- Stem with track numbers and bit depth / sample rate tags
  local stem1 = "01_STEM_Snare_Top_44k_24bit.WAV"
  assert_eq(core.clean_track_name(stem1), "Snare Top 44k 24bit", "Cleans complex stem prefix and extension")

  local classified1 = core.classify_track({ name = stem1 })
  assert_eq(classified1.key, "drums", "Classifies complex snare stem as drums")

  -- Acoustic Guitar with DI and mic positions
  local stem2 = "Stem-08_Acoustic_Gtr_Mic_L.aiff"
  assert_eq(core.clean_track_name(stem2), "Acoustic Gtr Mic L", "Cleans stem prefix and maintains L channel")

  local classified2 = core.classify_track({ name = stem2 })
  assert_eq(classified2.key, "guitars", "Classifies as guitars")

  -- Vocal Harmonies with uppercase BGV
  local stem3 = "14 - Vox_Lead_BGV_Harmonies.wav"
  assert_eq(core.clean_track_name(stem3), "VOX Lead BGV Harmonies", "Formats VOX and BGV properly")


  print("ok - complex_stem_names")
end


-- 3. Test folder nesting arithmetic and multi-group boundaries
local function test_folder_depth_math()
  local tracks = {
    { id = "1", name = "Kick" },
    { id = "2", name = "Snare" },
    { id = "3", name = "Bass DI" },
    { id = "4", name = "Lead Vox" },
    { id = "5", name = "BGV Harmony" },
    { id = "6", name = "Acoustic Gtr" }
  }

  local plan = core.build_plan(tracks, { create_folders = true })
  local insertions = core.folder_insertions(plan)

  assert_eq(#insertions, 4, "Creates 4 folder headers for 4 distinct groups")
  assert_eq(insertions[1].key, "drums", "Group 1 is drums")
  assert_eq(insertions[1].count, 2, "Drums has 2 tracks")
  assert_eq(insertions[1].folder_index_zero, 0, "Drums folder starts at index 0")
  assert_eq(insertions[1].last_child_index_zero, 2, "Drums last child is index 2")

  assert_eq(insertions[2].key, "bass", "Group 2 is bass")
  assert_eq(insertions[2].count, 1, "Bass has 1 track")
  assert_eq(insertions[2].folder_index_zero, 3, "Bass folder starts at index 3 (0 + 2 + 1 folder)")

  print("ok - folder_depth_math")
end

-- 4. Test strict palette validation for all color values
local function test_strict_palette_validity()
  for theme_key, theme in pairs(palettes.themes) do
    assert_eq(type(theme.name), "string", "Theme " .. theme_key .. " has string name")
    assert_eq(type(theme.colors), "table", "Theme " .. theme_key .. " has colors table")
    for _, cat in ipairs(lexicon.categories) do
      local col = theme.colors[cat.key]
      assert_eq(type(col), "number", "Color exists for " .. cat.key .. " in " .. theme_key)
      assert_eq(col >= 0 and col <= 0xFFFFFF, true, "Color is valid 24-bit RGB in " .. theme_key)
    end
  end
  print("ok - strict_palette_validity")
end

local function run_strict_tests()
  test_edge_case_inputs()
  test_complex_stem_names()
  test_folder_depth_math()
  test_strict_palette_validity()
  print("\n4 strict edge-case test suites passed.")
end

run_strict_tests()
