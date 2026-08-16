---@meta
local core = require "smart_track_organizer_core"
local adapter = require "reaper_adapter"

local ui_state = {}

---Create a new isolated UI state store instance
---@param reaper_api? table
---@return table state
function ui_state.create(reaper_api)
  local state = {
    reaper_api = reaper_api or _G.reaper,
    options = {},
    filter_text = "",
    selected_track_ids = {},
    overrides = {},
    raw_tracks = {},
    full_plan = nil,
    all_planned_map = {},
    display_items = {},
    active_count = 0,
    total_count = 0,
    summary_text = "",
    listeners = {},
  }

  state.options = adapter.load_options(state.reaper_api)

  ---Subscribe a callback to state changes
  ---@param fn function
  function state:on_change(fn)
    table.insert(self.listeners, fn)
  end

  ---Notify all listeners
  function state:notify()
    for _, fn in ipairs(self.listeners) do
      fn(self)
    end
  end

  ---Set search filter query
  ---@param text string
  function state:set_filter(text)
    self.filter_text = tostring(text or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    self:compute_display_items()
    self:notify()
  end

  ---Toggle selection for a specific track ID
  ---@param tid string|number
  ---@param is_checked boolean
  function state:set_track_selected(tid, is_checked)
    self.selected_track_ids[tid] = is_checked
    self:recalculate_plan()
  end

  ---Set select all state for all tracks
  ---@param is_checked boolean
  function state:set_all_selected(is_checked)
    for _, t in ipairs(self.raw_tracks) do
      self.selected_track_ids[t.id] = is_checked
    end
    self:recalculate_plan()
  end

  ---Update options and recalculate
  ---@param new_options table
  function state:update_options(new_options)
    for k, v in pairs(new_options) do
      self.options[k] = v
    end
    self:recalculate_plan()
  end

  ---Reload raw project tracks from REAPER
  ---@param reset_selection? boolean
  function state:reload_tracks(reset_selection)
    self.raw_tracks = adapter.collect_tracks(self.reaper_api)
    if reset_selection or not self._initialized_selection then
      self.selected_track_ids = {}
      for _, t in ipairs(self.raw_tracks) do
        self.selected_track_ids[t.id] = true
      end
      self._initialized_selection = true
    end
    self:recalculate_plan()
  end

  ---Filter display items matching active search query
  function state:compute_display_items()
    local display_items = {}
    local added_tids = {}

    if self.full_plan and self.full_plan.tracks then
      for _, p_track in ipairs(self.full_plan.tracks) do
        local tid = p_track.id or (p_track.track and p_track.track.id)
        local raw_t = p_track.track
        local matches = true
        if self.filter_text ~= "" and raw_t then
          local search_str = (raw_t.name .. " " .. (p_track.new_name or "") .. " " .. (p_track.category_label or "")):lower()
          if not search_str:find(self.filter_text, 1, true) then
            matches = false
          end
        end

        if matches then
          display_items[#display_items + 1] = {
            item = p_track,
            raw_track = raw_t,
            is_checked = true,
            tid = tid,
          }
        end
        if tid then
          added_tids[tid] = true
        end
      end
    end

    for _, raw_t in ipairs(self.raw_tracks) do
      if not raw_t.generated_folder and not added_tids[raw_t.id] then
        local item = self.all_planned_map[raw_t.id]
        local matches = true
        if self.filter_text ~= "" then
          local search_str = (raw_t.name .. " " .. (item and item.new_name or "") .. " " .. (item and item.category_label or "")):lower()
          if not search_str:find(self.filter_text, 1, true) then
            matches = false
          end
        end

        if matches then
          display_items[#display_items + 1] = {
            item = item,
            raw_track = raw_t,
            is_checked = false,
            tid = raw_t.id,
          }
        end
      end
    end

    self.display_items = display_items
  end

  ---Recalculate the organization plan
  function state:recalculate_plan()
    -- Only count actual project audio/instrument tracks (exclude STO generated folders)
    local project_tracks = {}
    for _, t in ipairs(self.raw_tracks) do
      if not t.generated_folder then
        project_tracks[#project_tracks + 1] = t
      end
    end

    self.total_count = #project_tracks
    if self.total_count == 0 then
      self.active_count = 0
      self.full_plan = nil
      self.summary_text = "No tracks found in current project."
      self.display_items = {}
      self:notify()
      return
    end

    for _, t in ipairs(project_tracks) do
      if self.overrides[t.id] then
        t.category_override = self.overrides[t.id]
      end
    end

    local active_tracks = {}
    for _, t in ipairs(project_tracks) do
      if self.selected_track_ids[t.id] then
        table.insert(active_tracks, t)
      end
    end
    self.active_count = #active_tracks

    self.full_plan = core.build_plan(active_tracks, self.options)

    local all_planned = core.build_plan(project_tracks, self.options)
    self.all_planned_map = {}
    for _, p_track in ipairs(all_planned.tracks) do
      local tid = p_track.id or (p_track.track and p_track.track.id)
      if tid then
        self.all_planned_map[tid] = p_track
      end
    end

    self.summary_text =
      string.format("Selected for Organization: %d of %d Tracks  |  Breakdown: %s", self.active_count, self.total_count, core.summarize_plan(self.full_plan))

    self:compute_display_items()
    self:notify()
  end

  state:reload_tracks(true)
  return state
end

return ui_state
