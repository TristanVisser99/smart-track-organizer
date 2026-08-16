---@meta
local theme = require "theme"
local draw = require "ui_draw_helpers"
local palettes = require "palettes"

local ui_components = {}

---Build top branding and theme palette selector header
---@param root table
---@param current_palette string
---@param on_palette_change function
---@return table palette_dropdown
function ui_components.build_header(root, current_palette, on_palette_change)
  local header_panel = root:add(
    rtk.HBox {
      padding = { 8, 12 },
      valign = "center",
      box = { expand = "x", fill = true },
    },
    { fillw = true, stretch = rtk.Box.STRETCH_FULL }
  )
  draw.make_rounded_card(header_panel, 8, theme.colors.bg_surface, theme.colors.border_card)

  local brand_box = header_panel:add(rtk.HBox { spacing = 8, valign = "center" })
  local brand_dot = brand_box:add(rtk.HBox { w = 10, h = 10 })
  draw.make_circle_dot(brand_dot, theme.colors.text_accent)

  brand_box:add(rtk.Heading {
    text = "Smart Track Organizer Pro",
    fontscale = theme.typography.title_scale,
    color = theme.colors.text_primary,
  })

  header_panel:add(rtk.Box.FLEXSPACE)

  local palette_box = header_panel:add(rtk.HBox { spacing = 6, valign = "center" }, { valign = "center" })
  palette_box:add(
    rtk.Text {
      text = "Palette:",
      fontscale = theme.typography.body_scale,
      color = theme.colors.text_secondary,
    },
    { valign = "center" }
  )

  local palette_menu = {
    { "Modern Studio", id = "modern" },
    { "Pastel Soft", id = "pastel" },
    { "Vintage Console", id = "vintage" },
    { "Cyber Neon", id = "neon" },
    { "Monochrome Slate", id = "minimal" },
  }

  local palette_dropdown = palette_box:add(
    rtk.OptionMenu {
      menu = palette_menu,
      selected = current_palette or "modern",
      color = "#1a1d26",
      textcolor = "#f1f5f9",
      textcolor2 = "#ffffff",
      fontscale = theme.typography.body_scale,
      rpadding = 22,
      lpadding = 10,
      tpadding = 5,
      bpadding = 5,
    },
    { valign = "center" }
  )
  palette_dropdown.onchange = on_palette_change

  return palette_dropdown
end

---Build Search Bar Row and Options Toolbar Row
---@param root table
---@param current_options table
---@param on_search function
---@param on_option_change function
---@return table search_entry, table chk_folders, table chk_prefix, table sort_dropdown
function ui_components.build_control_row(root, current_options, on_search, on_option_change)
  -- 1. Search Panel Card
  local search_entry
  local search_panel = root:add(
    rtk.HBox {
      padding = { 8, 12 },
      spacing = 8,
      valign = "center",
      box = { expand = "x", fill = true },
    },
    { fillw = true, stretch = rtk.Box.STRETCH_FULL }
  )

  search_panel.ondrawpre = function(self, offx, offy, alpha, event)
    local calc = self.calc
    local x = math.floor(calc.x + offx)
    local y = math.floor(calc.y + offy)
    local w = math.floor(calc.w)
    local h = math.floor(calc.h)

    local is_active = (self.hovering or (search_entry and (search_entry.hovering or search_entry:focused())))
    local border_color = is_active and theme.colors.border_focus or theme.colors.border_card

    if theme.colors.bg_surface then
      rtk.color.set(theme.colors.bg_surface)
      rtk.gfx.roundrect(x, y, w, h, 8, 0, 1)
    end
    rtk.color.set(border_color)
    rtk.gfx.roundrect(x, y, w, h, 8, 1, 1)
    return true
  end

  local search_icon_box = search_panel:add(rtk.HBox { w = 14, h = 14, valign = "center" }, { valign = "center" })
  search_icon_box.ondrawpre = function(self, offx, offy, alpha, event)
    local calc = self.calc
    local cx = math.floor(calc.x + offx) + 5
    local cy = math.floor(calc.y + offy) + 5
    local icon_color = (search_entry and (search_entry.hovering or search_entry:focused())) and theme.colors.text_accent or theme.colors.text_dim
    rtk.color.set(icon_color)
    gfx.circle(cx, cy, 4, 0, 1)
    gfx.line(cx + 3, cy + 3, cx + 7, cy + 7)
    return true
  end

  search_entry = search_panel:add(
    rtk.Entry {
      placeholder = "Search tracks by name, category, or stem role...",
      bg = "#00000000",
      border = nil,
      border_focused = nil,
      border_hover = nil,
      textcolor = theme.colors.text_primary,
      fontscale = theme.typography.body_scale,
      padding = { 2, 0 },
    },
    { valign = "center", expand = 1, fillw = true }
  )
  search_entry.onchange = on_search

  -- 2. Options Toolbar Card
  local toolbar_panel = root:add(
    rtk.HBox {
      padding = { 8, 12 },
      valign = "center",
      box = { expand = "x", fill = true },
    },
    { fillw = true, stretch = rtk.Box.STRETCH_FULL }
  )
  draw.make_rounded_card(toolbar_panel, 8, theme.colors.bg_surface, theme.colors.border_card)

  local options_left_box = toolbar_panel:add(rtk.HBox { spacing = 14, valign = "center" }, { valign = "center" })
  local chk_folders = options_left_box:add(
    rtk.CheckBox { label = "Folder Groups", value = current_options.create_folders, fontscale = theme.typography.body_scale },
    { valign = "center" }
  )
  local chk_prefix = options_left_box:add(
    rtk.CheckBox { label = "Prefix Codes", value = current_options.prefix_names, fontscale = theme.typography.body_scale },
    { valign = "center" }
  )

  toolbar_panel:add(rtk.Box.FLEXSPACE)

  local sort_box = toolbar_panel:add(rtk.HBox { spacing = 6, valign = "center" }, { valign = "center" })
  sort_box:add(
    rtk.Text {
      text = "Sort:",
      fontscale = theme.typography.body_scale,
      color = theme.colors.text_secondary,
    },
    { valign = "center" }
  )

  local sort_menu = {
    { "Studio Mix Order", id = "mix" },
    { "Vocal-First Flow", id = "vocal_first" },
    { "Alphabetical (A-Z)", id = "alpha" },
    { "Original Project Order", id = "none" },
  }

  local sort_dropdown = sort_box:add(
    rtk.OptionMenu {
      menu = sort_menu,
      selected = current_options.sort_mode or "mix",
      color = "#1a1d26",
      textcolor = "#f1f5f9",
      textcolor2 = "#ffffff",
      fontscale = theme.typography.body_scale,
      rpadding = 22,
      lpadding = 10,
      tpadding = 5,
      bpadding = 5,
    },
    { valign = "center" }
  )

  chk_folders.onchange = on_option_change
  chk_prefix.onchange = on_option_change
  sort_dropdown.onchange = on_option_change

  return search_entry, chk_folders, chk_prefix, sort_dropdown
end

---Build pinned column table headers with Master Select All Checkbox
---@param root table
---@param on_toggle_all function
---@return table chk_select_all
function ui_components.build_table_header(root, on_toggle_all)
  local table_header = root:add(
    rtk.HBox {
      padding = 8,
      spacing = 10,
      valign = "center",
      box = { expand = "x", fill = true },
    },
    { fillw = true, stretch = rtk.Box.STRETCH_FULL }
  )
  draw.make_rounded_card(table_header, 6, theme.colors.bg_header, theme.colors.border_card)

  local chk_select_all = table_header:add(rtk.CheckBox { value = true, fontscale = theme.typography.caption_scale })
  chk_select_all.onchange = on_toggle_all

  table_header:add(rtk.Text { text = "#", w = 32, fontscale = theme.typography.caption_scale, color = theme.colors.text_dim })
  table_header:add(rtk.Text { text = "Category", w = 136, fontscale = theme.typography.caption_scale, color = theme.colors.text_accent })
  table_header:add(rtk.Text { text = "Original Track Name", fontscale = theme.typography.caption_scale, color = theme.colors.text_secondary }, { expand = 1 })
  table_header:add(rtk.Text { text = "Organized Output (Live Preview)", fontscale = theme.typography.caption_scale, color = "#86efac" }, { expand = 1 })

  return chk_select_all
end

---Build flex-scrollable Viewport container for track preview rows
---@param root table
---@return table viewport, table table_vbox
function ui_components.build_viewport(root)
  local table_vbox = rtk.VBox {
    spacing = 3,
    box = { expand = "both", fill = true },
  }
  local viewport = root:add(
    rtk.Viewport {
      child = table_vbox,
      box = { expand = "both", fill = true },
      bg = theme.colors.bg_canvas,
      vscrollbar = rtk.Viewport.SCROLLBAR_ALWAYS,
      scrollbar_size = 6,
    },
    { fillw = true, stretch = rtk.Box.STRETCH_FULL, expand = 1 }
  )

  draw.make_rounded_card(viewport, 8, theme.colors.bg_canvas, theme.colors.border_card)

  return viewport, table_vbox
end

---Build live breakdown summary sentence bar
---@param root table
---@return table status_bar
function ui_components.build_status_bar(root)
  local status_bar = root:add(
    rtk.Text {
      text = "",
      color = theme.colors.text_secondary,
      fontscale = theme.typography.caption_scale,
      wrap = rtk.Text.WRAP_NORMAL,
      box = { expand = "x", fill = true },
    },
    { fillw = true, stretch = rtk.Box.STRETCH_FULL }
  )

  return status_bar
end

---Build bottom action buttons: Refresh Tracks and Apply Organization CTA
---@param root table
---@param on_refresh function
---@param on_apply function
---@return table btn_refresh, table btn_apply
function ui_components.build_button_bar(root, on_refresh, on_apply)
  local button_bar = root:add(
    rtk.HBox {
      spacing = 12,
      halign = "right",
      valign = "center",
      box = { expand = "x", fill = true },
    },
    { fillw = true, stretch = rtk.Box.STRETCH_FULL }
  )

  local btn_refresh = button_bar:add(
    rtk.Button {
      label = "Refresh Tracks",
      color = "#242735",
      textcolor = "#c9cedb",
      textcolor2 = "#ffffff",
      textcolor_hover = "#ffffff",
      fontscale = theme.typography.body_scale,
      padding = { 8, 16 },
    },
    { stretch = rtk.Box.STRETCH_TO_SIBLINGS, valign = "center" }
  )
  btn_refresh.onclick = on_refresh

  local btn_apply = button_bar:add(
    rtk.Button {
      label = "Apply Organization",
      color = "#238636",
      textcolor = "#ffffff",
      textcolor2 = "#ffffff",
      textcolor_hover = "#ffffff",
      fontscale = theme.typography.body_scale,
      padding = { 8, 22 },
    },
    { stretch = rtk.Box.STRETCH_TO_SIBLINGS, valign = "center" }
  )
  btn_apply.onclick = on_apply

  return btn_refresh, btn_apply
end

---Render all track rows inside the table container
---@param table_vbox table
---@param display_items table[]
---@param on_row_toggle function
function ui_components.render_preview_rows(table_vbox, display_items, on_row_toggle)
  table_vbox:remove_all()

  for idx, entry in ipairs(display_items) do
    local item = entry.item
    local is_checked = entry.is_checked
    local tid = entry.tid

    if item then
      local hex_color = palettes.rgb_to_hex(item.color)
      local row_bg = is_checked and ((idx % 2 == 0) and theme.colors.bg_row_even or theme.colors.bg_row_odd) or "#0b0c10"
      local row = table_vbox:add(
        rtk.HBox {
          padding = theme.spacing.row_padding,
          spacing = 10,
          valign = "center",
          box = { expand = "x", fill = true },
        },
        { fillw = true, stretch = rtk.Box.STRETCH_FULL }
      )
      draw.make_rounded_card(row, 6, row_bg, is_checked and theme.colors.border_card or "#14161f")

      -- In-GUI Track Checkbox
      local chk_row = row:add(rtk.CheckBox { value = is_checked, fontscale = theme.typography.caption_scale })
      chk_row.onchange = function(self)
        on_row_toggle(tid, self.value)
      end

      -- Index
      row:add(rtk.Text {
        text = is_checked and string.format("%02d", idx) or "--",
        w = 32,
        color = is_checked and theme.colors.text_dim or "#444856",
        fontscale = theme.typography.caption_scale,
      })

      -- Category Pill Badge with Dot
      local badge = row:add(rtk.HBox {
        w = 136,
        padding = 4,
        spacing = 6,
        valign = "center",
      })
      draw.make_rounded_card(badge, 6, is_checked and theme.colors.bg_surface_elev or "#11131a", is_checked and hex_color or "#2d3142")

      local cat_dot = badge:add(rtk.HBox { w = 8, h = 8 })
      draw.make_circle_dot(cat_dot, is_checked and hex_color or "#484c60")

      badge:add(rtk.Text {
        text = item.category_label,
        color = is_checked and hex_color or "#5c6075",
        fontscale = theme.typography.badge_scale,
      })

      -- Original Track Name
      row:add(
        rtk.Text {
          text = item.original_name,
          color = is_checked and theme.colors.text_secondary or "#505466",
          fontscale = theme.typography.body_scale,
        },
        { expand = 1 }
      )

      -- Output Organized Target Name
      row:add(
        rtk.Text {
          text = is_checked and item.new_name or "(Skipped / Unchanged)",
          color = is_checked and theme.colors.text_primary or "#404354",
          fontscale = theme.typography.body_scale,
        },
        { expand = 1 }
      )
    end
  end
end

return ui_components
