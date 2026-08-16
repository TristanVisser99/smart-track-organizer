---@meta
local adapter = require "reaper_adapter"
local theme = require "theme"
local draw = require "ui_draw_helpers"
local ui_state = require "ui_state"
local ui_components = require "ui_components"

local ui_rtk = {}

---Main Entry Point for launching the RTK User Interface
---@param rtk table
---@param reaper_api table
function ui_rtk.launch(rtk, reaper_api)
  draw.apply_modern_fonts(rtk)
  draw.setup_custom_rendering(rtk)

  local state = ui_state.create(reaper_api)

  local window = rtk.Window {
    title = "Smart Track Organizer Pro",
    w = 980,
    h = 660,
    minw = 780,
    minh = 500,
    resizable = true,
    dockable = true,
    bg = theme.colors.bg_canvas,
  }

  local root = window:add(rtk.VBox {
    padding = theme.spacing.window_padding,
    spacing = theme.spacing.gap_md,
    bg = theme.colors.bg_canvas,
    box = { expand = "both", fill = true },
  })

  -- Build UI Components
  ui_components.build_header(root, state.options.palette, function(self)
    state:update_options { palette = self.selected_id or self.selected }
  end)

  local _, chk_folders, chk_prefix, sort_dropdown
  _, chk_folders, chk_prefix, sort_dropdown = ui_components.build_control_row(root, state.options, function(self)
    state:set_filter(self.value)
  end, function()
    state:update_options {
      create_folders = chk_folders and chk_folders.value,
      prefix_names = chk_prefix and chk_prefix.value,
      sort_mode = sort_dropdown and (sort_dropdown.selected_id or sort_dropdown.selected or "mix") or "mix",
      sort_tracks = (sort_dropdown and ((sort_dropdown.selected_id or sort_dropdown.selected or "mix") ~= "none")),
    }
  end)

  ui_components.build_table_header(root, function(self)
    state:set_all_selected(self.value)
  end)

  local _, table_vbox = ui_components.build_viewport(root)
  local status_bar = ui_components.build_status_bar(root)

  ui_components.build_button_bar(root, function()
    state:reload_tracks(true)
  end, function()
    if state.full_plan and #state.full_plan.tracks > 0 then
      adapter.save_options(state.options, reaper_api)
      adapter.execute_plan(state.full_plan, reaper_api)
      window:close()
    end
  end)

  -- Connect reactive state listener to UI
  state:on_change(function(s)
    status_bar:attr("text", s.summary_text)
    ui_components.render_preview_rows(table_vbox, s.display_items, function(tid, is_checked)
      s:set_track_selected(tid, is_checked)
    end)
  end)

  -- Initial render
  state:notify()
  window:open()
end

return ui_rtk
