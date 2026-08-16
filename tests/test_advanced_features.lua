package.path = "src/?.lua;" .. package.path

local core = require("smart_track_organizer_core")

local function assert_eq(actual, expected, message)
  if actual ~= expected then
    error(string.format("%s: expected '%s', got '%s'", message or "Assertion failed", tostring(expected), tostring(actual)))
  end
end

local function test_palettes_support()
  local palettes = { "modern", "pastel", "vintage", "neon", "minimal" }
  for _, p in ipairs(palettes) do
    local pal = core.get_palette(p)
    assert_eq(pal ~= nil, true, "Palette exists: " .. p)
    assert_eq(type(pal.colors.drums), "number", "Drums color exists in " .. p)
  end
  print("ok - all 5 studio palettes valid")
end

local function test_fx_clues_classification()
  -- An ambiguous track named "Track 03" with Serum plugin loaded
  local track = {
    name = "Track 03",
    fx_names = { "VSTi: Serum (Xfer Records)" }
  }
  local res = core.classify_track(track)
  assert_eq(res.key, "synths", "Classifies as synth based on Serum FX plugin")

  -- An ambiguous track named "Inst 1" with Superior Drummer
  local track_drums = {
    name = "Inst 1",
    fx_names = { "VST3i: Superior Drummer 3 (Toontrack)" }
  }
  local res_drums = core.classify_track(track_drums)
  assert_eq(res_drums.key, "drums", "Classifies as drums based on Superior Drummer FX plugin")

  -- Guitar Rig
  local track_gtr = {
    name = "Audio 5",
    fx_names = { "VST: Guitar Rig 6 (Native Instruments)" }
  }
  local res_gtr = core.classify_track(track_gtr)
  assert_eq(res_gtr.key, "guitars", "Classifies as guitars based on Guitar Rig FX plugin")

  print("ok - fx_context_classification")
end

local function test_advanced_acronym_preservation()
  assert_eq(core.clean_track_name("01_kick_in_di.wav"), "Kick in DI", "Preserves uppercase DI and strips .wav")
  assert_eq(core.clean_track_name("lead_vox_bgv_dbl"), "Lead VOX BGV DBL", "Preserves uppercase BGV and DBL")
  assert_eq(core.clean_track_name("mix_bus_ny_crush"), "Mix Bus NY Crush", "Preserves uppercase NY")
  assert_eq(core.clean_track_name("stem_04 - acoustic_gtr_l"), "Acoustic Gtr L", "Cleans stem prefix and preserves channel L")
  print("ok - advanced_acronym_preservation")
end


local function test_manual_category_override()
  local tracks = {
    { id = "t1", name = "Crazy Sound FX", category_override = "keys" },
    { id = "t2", name = "Bass Sub" }
  }
  local plan = core.build_plan(tracks, { prefix_names = true })
  local overridden = nil
  for _, item in ipairs(plan.tracks) do
    if item.id == "t1" then
      overridden = item
      break
    end
  end
  assert_eq(overridden ~= nil, true, "Found track t1")
  assert_eq(overridden.category_key, "keys", "Honors manual override to Keys")
  assert_eq(overridden.new_name, "KEY - Crazy Sound FX", "Prefixes overridden category")
  print("ok - manual_category_override")
end


local function test_sort_mode_strategies()
  local tracks = {
    { id = 1, name = "Acoustic Guitar" },
    { id = 2, name = "Lead Vocal" },
    { id = 3, name = "Kick In" },
    { id = 4, name = "Bass DI" }
  }

  -- 1. Vocal First
  local vf_plan = core.build_plan(tracks, { sort_mode = "vocal_first" })
  assert_eq(vf_plan.tracks[1].category_key, "vocals", "Vocal first puts vocals at index 1")
  assert_eq(vf_plan.tracks[2].category_key, "drums", "Drums second in vocal first")

  -- 2. Alphabetical
  local alpha_plan = core.build_plan(tracks, { sort_mode = "alpha" })
  assert_eq(alpha_plan.tracks[1].clean_name, "Acoustic Guitar", "Alphabetical puts Acoustic Guitar first")
  assert_eq(alpha_plan.tracks[2].clean_name, "Bass DI", "Bass DI is second alphabetically")


  -- 3. Original Project Order (None)
  local none_plan = core.build_plan(tracks, { sort_mode = "none" })
  assert_eq(none_plan.tracks[1].original_name, "Acoustic Guitar", "Original order preserved 1")
  assert_eq(none_plan.tracks[2].original_name, "Lead Vocal", "Original order preserved 2")
  assert_eq(none_plan.tracks[3].original_name, "Kick In", "Original order preserved 3")
  assert_eq(none_plan.tracks[4].original_name, "Bass DI", "Original order preserved 4")

  print("ok - sort_mode_multi_strategies")
end

local function run_all()
  test_palettes_support()
  test_fx_clues_classification()
  test_advanced_acronym_preservation()
  test_manual_category_override()
  test_sort_mode_strategies()
  print("\n5 advanced feature tests passed")
end

run_all()
