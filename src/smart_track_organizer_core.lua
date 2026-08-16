---@meta

local palettes = require("palettes")
local lexicon = require("lexicon")

---@class TrackCandidate
---@field id string
---@field track table
---@field original_index integer
---@field original_name string
---@field clean_name string
---@field new_name string
---@field category_key string
---@field category_label string
---@field category_prefix string
---@field category_order integer
---@field color number
---@field role_rank integer
---@field score number
---@field new_index? integer

---@class GroupSummary
---@field key string
---@field label string
---@field prefix string
---@field color number
---@field first_index integer
---@field count integer

---@class OrganizationPlan
---@field version string
---@field palette string
---@field options table
---@field tracks TrackCandidate[]
---@field groups GroupSummary[]

---@class FolderInsertion
---@field key string
---@field label string
---@field color number
---@field count integer
---@field insert_at_zero integer
---@field folder_index_zero integer
---@field last_child_index_zero integer

local core = {}

core.VERSION = "2.0.0"
core.DEFAULT_PALETTE = palettes.DEFAULT
core.categories = lexicon.categories
core.palettes = palettes.themes

---Get palette theme by name
---@param name? string
---@return PaletteTheme
function core.get_palette(name)
  return palettes.get(name)
end

---Get RGB color integer for a given category and palette
---@param category_key string
---@param palette_name? string
---@return number
function core.get_category_color(category_key, palette_name)
  return palettes.get_color(category_key, palette_name)
end

local function clone_shallow(value)
  local copy = {}
  for key, item in pairs(value) do
    copy[key] = item
  end
  return copy
end

---Normalize a track name for token matching
---@param value any
---@return string
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

local function score_category(normalized, category, fx_names)
  local score = 0
  for _, token in ipairs(category.tokens or {}) do
    if contains_token(normalized, token) then
      score = score + (#token * 2)
    end
  end

  -- Contextual FX clues scoring
  if fx_names and #fx_names > 0 then
    for _, fx in ipairs(fx_names) do
      local fx_norm = normalize(fx)
      for _, clue in ipairs(category.fx_clues or {}) do
        if contains_token(fx_norm, clue) then
          score = score + 15
        end
      end
    end
  end

  return score
end

---Classify a track based on name and loaded FX plugin clues
---@param track_info table|string
---@return CategoryDefinition
function core.classify_track(track_info)
  local name = type(track_info) == "table" and track_info.name or tostring(track_info or "")
  local fx_list = type(track_info) == "table" and track_info.fx_names or {}
  local normalized = normalize(name)
  local best = lexicon.category_by_key.other
  local best_score = 0

  for _, category in ipairs(lexicon.categories) do
    if category.key ~= "other" then
      local score = score_category(normalized, category, fx_list)
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

---Classify track name only
---@param name string
---@return CategoryDefinition
function core.classify_track_name(name)
  return core.classify_track({ name = name })
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
  local lower = word:lower()
  if lexicon.acronyms[lower] then
    return lexicon.acronyms[lower]
  end
  if word:upper() == word and #word <= 4 then
    return word
  end
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

---Clean and format track name according to audio engineering conventions
---@param name any
---@return string
function core.clean_track_name(name)
  local value = tostring(name or "")
  -- Remove common audio file extensions
  value = value:gsub("%.%a%a%a+$", "")
  -- Remove stem leading numbers like "01_", "Stem_02 - ", "01_STEM_"
  value = value:gsub("^%s*%d+[%s%._%-:]+", "")
  value = value:gsub("^%s*[Ss][Tt][Ee][Mm]%s*[%-_%d]*%s*[%-_:]%s*", "")
  value = value:gsub("^%s*%d+[%s%._%-:]+", "")
  value = value:gsub("^%s*%[[^%]]+%]%s*", "")

  for _, prefix in ipairs(lexicon.removable_prefixes) do
    value = value:gsub("^[ \t]*" .. prefix:lower() .. "[ \t]*[%-%:_][ \t]*", "")
    value = value:gsub("^[ \t]*" .. prefix:upper() .. "[ \t]*[%-%:_][ \t]*", "")
  end

  value = value:gsub("[_%./\\]+", " ")
  value = value:gsub("%s*%-%s*", " - ")
  value = value:gsub("%s+", " ")
  value = value:gsub("^%s+", ""):gsub("%s+$", "")

  if value == "" or value:lower():match("^track%s*%d*$") or not value:match("%w") then
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

-- Vocal-first category priority mapping
local vocal_first_priority = {
  vocals = 1,
  drums = 2,
  bass = 3,
  synths = 4,
  keys = 5,
  guitars = 6,
  orchestral = 7,
  fx = 8,
  returns = 9,
  other = 10,
  reference = 11
}

local function get_sort_comparator(sort_mode)
  if sort_mode == "vocal_first" then
    return function(a, b)
      local a_ord = vocal_first_priority[a.category_key] or 99
      local b_ord = vocal_first_priority[b.category_key] or 99
      if a_ord ~= b_ord then
        return a_ord < b_ord
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
  elseif sort_mode == "alpha" then
    return function(a, b)
      local an = normalize(a.clean_name)
      local bn = normalize(b.clean_name)
      if an ~= bn then
        return an < bn
      end
      return a.original_index < b.original_index
    end
  else
    -- Default standard studio mix order
    return function(a, b)
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
  end
end

---Build a comprehensive organization plan from collected tracks
---@param tracks table[]
---@param options? table
---@return OrganizationPlan
function core.build_plan(tracks, options)
  options = options or {}
  local palette_name = options.palette or core.DEFAULT_PALETTE
  local candidates = {}
  local selected_only = options.selected_only == true

  for index, track in ipairs(tracks or {}) do
    local include = not track.generated_folder
    if selected_only then
      include = include and track.selected == true
    end
    if include then
      local category = core.classify_track(track)
      -- Allow manual override from UI if provided
      if track.category_override and lexicon.category_by_key[track.category_override] then
        category = clone_shallow(lexicon.category_by_key[track.category_override])
        category.role_rank = 1
        category.score = 100
      end

      local clean_name = core.clean_track_name(track.name)
      local category_color = palettes.get_color(category.key, palette_name)

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
        color = category_color,
        role_rank = category.role_rank or 999,
        score = category.score or 0
      }
    end
  end

  local sort_mode = options.sort_mode
  if sort_mode == nil then
    sort_mode = (options.sort_tracks == false) and "none" or "mix"
  end

  if sort_mode ~= "none" and options.sort_tracks ~= false then
    local comp = get_sort_comparator(sort_mode)
    table.sort(candidates, comp)
  end


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
    palette = palette_name,
    options = options,
    tracks = candidates,
    groups = groups
  }
end

---Summarize plan into a human-readable string
---@param plan OrganizationPlan
---@return string
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

---Calculate folder insertion positions for REAPER tracks
---@param plan OrganizationPlan
---@return FolderInsertion[]
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
