local core = {}

core.VERSION = "1.0.0"

local DEFAULT_COLOR = 0x6E6E6E

core.categories = {
  {
    key = "drums",
    label = "Drums",
    prefix = "DRM",
    color = 0xD94B3D,
    tokens = {
      "drum", "drums", "kick", "bd", "snare", "sd", "rim", "clap", "hat",
      "hihat", "hi hat", "tom", "toms", "ride", "crash", "cymbal", "perc",
      "percussion", "overhead", "oh", "drum room", "drums room", "kit room",
      "breakbeat"
    },
    role_order = {
      "kick", "bd", "snare", "sd", "clap", "hat", "hihat", "hi hat", "tom",
      "toms", "overhead", "oh", "drum room", "drums room", "kit room", "perc",
      "percussion"
    }
  },
  {
    key = "bass",
    label = "Bass",
    prefix = "BAS",
    color = 0x3F7D20,
    tokens = { "bass", "sub", "808", "low end", "upright" },
    role_order = { "sub", "808", "bass", "upright" }
  },
  {
    key = "vocals",
    label = "Vocals",
    prefix = "VOX",
    color = 0x8E5AD7,
    tokens = {
      "vox", "vocal", "vocals", "lead vox", "lead vocal", "backing", "bvox",
      "bgv", "choir", "adlib", "ad lib", "harmony", "harmonies", "double"
    },
    role_order = {
      "lead vox", "lead vocal", "vocal", "vox", "double", "harmony",
      "harmonies", "backing", "bvox", "bgv", "adlib", "ad lib"
    }
  },
  {
    key = "guitars",
    label = "Guitars",
    prefix = "GTR",
    color = 0xD69A2D,
    tokens = {
      "gtr", "guitar", "guitars", "acoustic", "electric", "rhythm gtr",
      "lead gtr", "dist guitar", "clean guitar"
    },
    role_order = {
      "acoustic", "rhythm gtr", "lead gtr", "clean guitar", "dist guitar",
      "gtr", "guitar"
    }
  },
  {
    key = "keys",
    label = "Keys",
    prefix = "KEY",
    color = 0x2F86A6,
    tokens = {
      "keys", "keyboard", "piano", "rhodes", "wurli", "organ", "epiano",
      "electric piano", "clav", "melotron"
    },
    role_order = { "piano", "rhodes", "wurli", "organ", "keys", "keyboard" }
  },
  {
    key = "synths",
    label = "Synths",
    prefix = "SYN",
    color = 0x40A7A0,
    tokens = {
      "synth", "synths", "pad", "lead synth", "arp", "pluck", "sequence",
      "seq", "texture"
    },
    role_order = { "pad", "lead synth", "arp", "pluck", "sequence", "seq", "synth" }
  },
  {
    key = "strings",
    label = "Strings",
    prefix = "STR",
    color = 0xB56B84,
    tokens = { "string", "strings", "violin", "viola", "cello", "contrabass" },
    role_order = { "violin", "viola", "cello", "contrabass", "strings" }
  },
  {
    key = "brass",
    label = "Brass/Winds",
    prefix = "HORN",
    color = 0xC8A13A,
    tokens = {
      "brass", "horn", "horns", "trumpet", "trombone", "sax", "saxophone",
      "flute", "clarinet", "woodwind"
    },
    role_order = { "trumpet", "trombone", "sax", "saxophone", "flute", "clarinet", "horn" }
  },
  {
    key = "fx",
    label = "FX",
    prefix = "FX",
    color = 0x6C8AE4,
    tokens = {
      "fx", "sfx", "riser", "impact", "sweep", "whoosh", "noise", "downlifter",
      "uplifter", "reverse", "transition"
    },
    role_order = { "riser", "impact", "sweep", "whoosh", "downlifter", "uplifter", "fx" }
  },
  {
    key = "returns",
    label = "Returns/Buses",
    prefix = "BUS",
    color = 0x757575,
    tokens = {
      "bus", "buss", "aux", "send", "return", "reverb", "delay", "verb",
      "parallel", "stem", "group"
    },
    role_order = { "reverb", "verb", "delay", "parallel", "bus", "aux", "return" }
  },
  {
    key = "reference",
    label = "Reference",
    prefix = "REF",
    color = 0x9A9A9A,
    tokens = { "ref", "reference", "rough", "demo", "print", "bounce", "master", "mix" },
    role_order = { "reference", "ref", "rough", "demo", "print", "bounce", "master" }
  },
  {
    key = "other",
    label = "Other",
    prefix = "MISC",
    color = DEFAULT_COLOR,
    tokens = {},
    role_order = {}
  }
}

local category_by_key = {}
for index, category in ipairs(core.categories) do
  category.order = index
  category_by_key[category.key] = category
end

local function clone_shallow(value)
  local copy = {}
  for key, item in pairs(value) do
    copy[key] = item
  end
  return copy
end

local function normalize(value)
  value = tostring(value or ""):lower()
  value = value:gsub("[_%-%./\\]+", " ")
  value = value:gsub("%s+", " ")
  value = value:gsub("^%s+", ""):gsub("%s+$", "")
  return value
end

core.normalize = normalize

local function contains_token(normalized, token)
  token = normalize(token)
  if token == "" then
    return false
  end
  return (" " .. normalized .. " "):find(" " .. token .. " ", 1, true) ~= nil
end

local function role_rank(normalized, category)
  for index, token in ipairs(category.role_order or {}) do
    if contains_token(normalized, token) then
      return index
    end
  end
  return 999
end

local function score_category(normalized, category)
  local score = 0
  for _, token in ipairs(category.tokens or {}) do
    if contains_token(normalized, token) then
      score = score + #token
    end
  end
  return score
end

function core.classify_track_name(name)
  local normalized = normalize(name)
  local best = category_by_key.other
  local best_score = 0

  for _, category in ipairs(core.categories) do
    if category.key ~= "other" then
      local score = score_category(normalized, category)
      if score > best_score then
        best = category
        best_score = score
      end
    end
  end

  local result = clone_shallow(best)
  result.score = best_score
  result.role_rank = role_rank(normalized, best)
  return result
end

local titlecase_small_words = {
  a = true,
  an = true,
  ["and"] = true,
  at = true,
  ["for"] = true,
  ["in"] = true,
  of = true,
  ["on"] = true,
  the = true,
  ["to"] = true
}

local function titlecase_word(word, index)
  if word:upper() == word and #word <= 4 then
    return word
  end
  local lower = word:lower()
  if index > 1 and titlecase_small_words[lower] then
    return lower
  end
  return lower:gsub("^%l", string.upper)
end

local function titlecase(value)
  local words = {}
  for word in tostring(value or ""):gmatch("%S+") do
    words[#words + 1] = titlecase_word(word, #words + 1)
  end
  return table.concat(words, " ")
end

local removable_prefixes = {
  "DRM", "BAS", "VOX", "GTR", "KEY", "SYN", "STR", "HORN", "FX", "BUS", "REF", "MISC"
}

function core.clean_track_name(name)
  local value = tostring(name or "")
  value = value:gsub("^%s*%d+[%s%._%-:]+", "")
  value = value:gsub("^%s*%[[^%]]+%]%s*", "")
  for _, prefix in ipairs(removable_prefixes) do
    value = value:gsub("^%s*" .. prefix .. "%s*[%-%:]%s*", "")
  end
  value = value:gsub("[_%./\\]+", " ")
  value = value:gsub("%s*%-%s*", " - ")
  value = value:gsub("%s+", " ")
  value = value:gsub("^%s+", ""):gsub("%s+$", "")

  if value == "" or value:lower():match("^track%s*%d*$") then
    return "Untitled"
  end

  return titlecase(value)
end

local function format_name(track, category, options)
  local clean_name = core.clean_track_name(track.name)
  if options.rename == false then
    return track.name
  end
  if options.prefix_names == false then
    return clean_name
  end
  return string.format("%s - %s", category.prefix, clean_name)
end

local function compare_planned(a, b)
  if a.category_order ~= b.category_order then
    return a.category_order < b.category_order
  end
  if a.role_rank ~= b.role_rank then
    return a.role_rank < b.role_rank
  end
  local an = normalize(a.clean_name)
  local bn = normalize(b.clean_name)
  if an ~= bn then
    return an < bn
  end
  return a.original_index < b.original_index
end

function core.build_plan(tracks, options)
  options = options or {}
  local candidates = {}
  local selected_only = options.selected_only == true

  for index, track in ipairs(tracks or {}) do
    local include = not track.generated_folder
    if selected_only then
      include = include and track.selected == true
    end
    if include then
      local category = core.classify_track_name(track.name)
      local clean_name = core.clean_track_name(track.name)
      candidates[#candidates + 1] = {
        id = track.id or index,
        track = track,
        original_index = index,
        original_name = track.name,
        clean_name = clean_name,
        new_name = format_name(track, category, options),
        category_key = category.key,
        category_label = category.label,
        category_prefix = category.prefix,
        category_order = category.order,
        color = category.color or DEFAULT_COLOR,
        role_rank = category.role_rank or 999,
        score = category.score or 0
      }
    end
  end

  table.sort(candidates, compare_planned)

  local seen_categories = {}
  local groups = {}
  for new_index, item in ipairs(candidates) do
    item.new_index = new_index
    if not seen_categories[item.category_key] then
      seen_categories[item.category_key] = {
        key = item.category_key,
        label = item.category_label,
        prefix = item.category_prefix,
        color = item.color,
        first_index = new_index,
        count = 0
      }
      groups[#groups + 1] = seen_categories[item.category_key]
    end
    seen_categories[item.category_key].count = seen_categories[item.category_key].count + 1
  end

  return {
    version = core.VERSION,
    options = options,
    tracks = candidates,
    groups = groups
  }
end

function core.summarize_plan(plan)
  local parts = {}
  for _, group in ipairs(plan.groups or {}) do
    parts[#parts + 1] = string.format("%s: %d", group.label, group.count)
  end
  if #parts == 0 then
    return "No tracks matched the current scope."
  end
  return table.concat(parts, ", ")
end

function core.folder_insertions(plan)
  local insertions = {}
  local inserted = 0
  for _, group in ipairs(plan.groups or {}) do
    local insert_at_zero = group.first_index - 1 + inserted
    insertions[#insertions + 1] = {
      key = group.key,
      label = group.label,
      color = group.color,
      count = group.count,
      insert_at_zero = insert_at_zero,
      folder_index_zero = insert_at_zero,
      last_child_index_zero = insert_at_zero + group.count
    }
    inserted = inserted + 1
  end
  return insertions
end

return core
