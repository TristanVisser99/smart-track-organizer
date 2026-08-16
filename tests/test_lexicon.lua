package.path = "src/?.lua;" .. package.path

local lexicon = require("lexicon")

local function assert_eq(actual, expected, message)
  if actual ~= expected then
    error(string.format("%s: expected '%s', got '%s'", message or "Assertion failed", tostring(expected), tostring(actual)))
  end
end

local function test_lexicon_categories()
  assert_eq(#lexicon.categories, 12, "Lexicon contains exactly 12 main categories")
  for _, cat in ipairs(lexicon.categories) do
    assert_eq(type(cat.key), "string", "Category has key")
    assert_eq(type(cat.label), "string", "Category has label")
    assert_eq(type(cat.prefix), "string", "Category has prefix code")
    assert_eq(type(cat.tokens), "table", "Category has token table")
  end
  print("ok - lexicon categories and schemas verified")
end

local function test_acronym_dictionary()
  assert_eq(lexicon.acronyms["di"], "DI", "Acronym DI mapped")
  assert_eq(lexicon.acronyms["bgv"], "BGV", "Acronym BGV mapped")
  assert_eq(lexicon.acronyms["fx"], "FX", "Acronym FX mapped")
  assert_eq(lexicon.acronyms["vca"], "VCA", "Acronym VCA mapped")
  print("ok - audio acronym dictionary verified")
end

test_lexicon_categories()
test_acronym_dictionary()
print("\nLexicon test suite passed.")
