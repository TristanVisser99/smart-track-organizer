package.path = "./src/?.lua;" .. package.path

local core = require("smart_track_organizer_core")

local tests = {}

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

local function track(name, selected)
  return { name = name, selected = selected ~= false }
end

function tests.classifies_common_track_names()
  local cases = {
    { "Kick In", "drums" },
    { "SNARE top", "drums" },
    { "808 Sub", "bass" },
    { "Lead Vocal Main", "vocals" },
    { "BVOX stack", "vocals" },
    { "Acoustic Guitar L", "guitars" },
    { "Rhodes", "keys" },
    { "Warm Pad", "synths" },
    { "Cello Close", "strings" },
    { "Trumpet 1", "brass" },
    { "Riser FX", "fx" },
    { "Plate Reverb Return", "returns" },
    { "Reference Mix", "reference" },
    { "Mystery Audio", "other" }
  }

  for _, case in ipairs(cases) do
    assert_equal(core.classify_track_name(case[1]).key, case[2], "wrong category for " .. case[1])
  end
end

function tests.classification_uses_word_boundaries()
  assert_equal(core.classify_track_name("That Weird Sound").key, "other")
  assert_equal(core.classify_track_name("Embassy Ambience").key, "other")
  assert_equal(core.classify_track_name("Carpet Room Tone").key, "other")
end

function tests.mix_bus_prefers_returns_over_reference()
  local result = core.classify_track_name("Mix Bus")
  assert_equal(result.key, "returns")
end

function tests.cleans_names_without_destroying_useful_labels()
  assert_equal(core.clean_track_name("01_KICK.in"), "KICK in")
  assert_equal(core.clean_track_name("[VOX] lead_vocal"), "Lead Vocal")
  assert_equal(core.clean_track_name("GTR - rhythm L"), "Rhythm L")
  assert_equal(core.clean_track_name("DRM - Kick"), "Kick")
  assert_equal(core.clean_track_name("Track 12"), "Untitled")
  assert_equal(core.clean_track_name("BGV stack 02"), "BGV Stack 02")
end

function tests.builds_sorted_rename_color_plan()
  local plan = core.build_plan({
    track("Lead Vocal"),
    track("Kick"),
    track("Bass DI"),
    track("Acoustic Guitar"),
    track("Plate Reverb Return")
  })

  assert_equal(#plan.tracks, 5)
  assert_equal(plan.tracks[1].category_key, "drums")
  assert_equal(plan.tracks[1].new_name, "DRM - Kick")
  assert_equal(plan.tracks[2].category_key, "bass")
  assert_equal(plan.tracks[3].category_key, "vocals")
  assert_equal(plan.tracks[4].category_key, "guitars")
  assert_equal(plan.tracks[5].category_key, "returns")
  assert_true(plan.tracks[1].color ~= plan.tracks[2].color, "drums and bass should receive different colors")
end

function tests.groups_are_contiguous_and_counted()
  local plan = core.build_plan({
    track("Snare"),
    track("Kick"),
    track("Lead Vox"),
    track("BGV"),
    track("Noise Sweep")
  })

  assert_equal(#plan.groups, 3)
  assert_equal(plan.groups[1].label, "Drums")
  assert_equal(plan.groups[1].count, 2)
  assert_equal(plan.groups[2].label, "Vocals")
  assert_equal(plan.groups[2].count, 2)
  assert_equal(plan.groups[3].label, "FX")
  assert_equal(plan.groups[3].count, 1)
end

function tests.drum_roles_sort_in_mix_friendly_order()
  local plan = core.build_plan({
    track("Drum Room"),
    track("Hat"),
    track("Snare Top"),
    track("Kick Out"),
    track("Tom Floor")
  })

  assert_equal(plan.tracks[1].new_name, "DRM - Kick Out")
  assert_equal(plan.tracks[2].new_name, "DRM - Snare Top")
  assert_equal(plan.tracks[3].new_name, "DRM - Hat")
  assert_equal(plan.tracks[4].new_name, "DRM - Tom Floor")
  assert_equal(plan.tracks[5].new_name, "DRM - Drum Room")
end

function tests.rename_false_keeps_original_names()
  local plan = core.build_plan({ track("lead_vocal") }, { rename = false })
  assert_equal(plan.tracks[1].new_name, "lead_vocal")
end

function tests.selected_only_scope_ignores_unselected_tracks()
  local plan = core.build_plan({
    track("Kick", true),
    track("Bass", false),
    track("Lead Vocal", true)
  }, { selected_only = true })

  assert_equal(#plan.tracks, 2)
  assert_equal(plan.tracks[1].original_name, "Kick")
  assert_equal(plan.tracks[2].original_name, "Lead Vocal")
end

function tests.selected_only_empty_scope_returns_noop_plan()
  local plan = core.build_plan({
    track("Kick", false),
    track("Lead Vocal", false)
  }, { selected_only = true })

  assert_equal(#plan.tracks, 0)
  assert_equal(#plan.groups, 0)
  assert_equal(core.summarize_plan(plan), "No tracks matched the current scope.")
end

function tests.options_can_disable_name_prefixes()
  local plan = core.build_plan({ track("lead_vocal") }, { prefix_names = false })
  assert_equal(plan.tracks[1].new_name, "Lead Vocal")
end

function tests.generated_folders_are_ignored()
  local plan = core.build_plan({
    { name = "STO - Drums", generated_folder = true },
    track("Kick"),
    track("Snare")
  })

  assert_equal(#plan.tracks, 2)
  assert_equal(plan.groups[1].count, 2)
end

function tests.folder_insertions_use_zero_based_reaper_indices()
  local plan = core.build_plan({
    track("Lead Vocal"),
    track("Kick"),
    track("Bass DI")
  })
  local insertions = core.folder_insertions(plan)

  assert_equal(insertions[1].label, "Drums")
  assert_equal(insertions[1].insert_at_zero, 0)
  assert_equal(insertions[1].last_child_index_zero, 1)
  assert_equal(insertions[2].label, "Bass")
  assert_equal(insertions[2].insert_at_zero, 2)
  assert_equal(insertions[2].last_child_index_zero, 3)
  assert_equal(insertions[3].label, "Vocals")
  assert_equal(insertions[3].insert_at_zero, 4)
  assert_equal(insertions[3].last_child_index_zero, 5)
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
  io.write(string.format("\n%d tests passed\n", passed))
end

run()
