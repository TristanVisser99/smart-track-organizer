package.path = "src/?.lua;" .. package.path

local palettes = require("palettes")

local function assert_eq(actual, expected, message)
  if actual ~= expected then
    error(string.format("%s: expected '%s', got '%s'", message or "Assertion failed", tostring(expected), tostring(actual)))
  end
end

local function test_palettes_completeness()
  local names = { "modern", "pastel", "vintage", "neon", "minimal" }
  local categories = { "drums", "bass", "vocals", "guitars", "keys", "synths", "strings", "brass", "fx", "returns", "reference", "other" }

  for _, name in ipairs(names) do
    local p = palettes.get(name)
    assert_eq(p ~= nil, true, "Palette " .. name .. " exists")
    for _, cat in ipairs(categories) do
      local col = palettes.get_color(cat, name)
      assert_eq(type(col), "number", "Color exists for " .. cat .. " in " .. name)
      assert_eq(col > 0, true, "Color is positive integer for " .. cat)
    end
  end
  print("ok - palettes completeness verified across all 5 themes")
end

local function test_hex_conversion()
  assert_eq(palettes.rgb_to_hex(0xD94B3D), "#d94b3d", "Converts RGB to lowercase hex")
  assert_eq(palettes.rgb_to_hex(0x00FF88), "#00ff88", "Converts neon green hex with leading zero")
  print("ok - rgb_to_hex formatting")
end

test_palettes_completeness()
test_hex_conversion()
print("\nPalettes test suite passed.")
