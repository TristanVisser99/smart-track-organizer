---@meta
local theme = require "theme"

local ui_draw_helpers = {}

---Discover best available modern font on the host system and configure RTK theme
---@param rtk table
function ui_draw_helpers.apply_modern_fonts(rtk)
  if not rtk then
    return
  end

  if rtk.scale then
    rtk.scale.user = 1.05
  end
  if rtk.font then
    rtk.font.multiplier = 1.05
  end

  if rtk.theme and theme.typography and theme.typography.preferred_fonts then
    for _, font_name in ipairs(theme.typography.preferred_fonts) do
      local test_idx = 1
      if gfx and gfx.setfont then
        gfx.setfont(test_idx, font_name, 16)
        local w = gfx.measurestr "AaBb123"
        if w and w > 0 then
          rtk.theme.default_font = { font_name, 16 }
          rtk.theme.heading_font = { font_name, 22 }
          rtk.theme.tooltip_font = { font_name, 14 }
          break
        end
      end
    end
  end
end

---Configure custom modern Apple-style vector rendering for Buttons, Checkboxes, and Entries
---@param rtk table
function ui_draw_helpers.setup_custom_rendering(rtk)
  if not rtk then
    return
  end

  -- 1. Smooth Apple-style rounded corner drawing for Buttons and OptionMenu dropdowns
  if rtk.Button then
    function rtk.Button:_draw_rectangular_button(x, y, hover, clicked, gradient, brightness, cmul, bmul, alpha)
      local calc = self.calc
      local pre = self._pre
      local amul = calc.alpha * alpha
      local is_menu = (self._menu ~= nil or self.class.name == "rtk.OptionMenu")
      local label_over_surface = calc.surface and (calc.flat == rtk.Button.RAISED or hover or is_menu)
      local textcolor = label_over_surface and calc.textcolor or calc.textcolor2
      local draw_surface = label_over_surface or (calc.label and calc.tagged and calc.surface)
      local surx = x + pre.surx
      local sury = y + pre.sury
      local surw = pre.surw
      local surh = pre.surh
      local radius = 6

      if surw > 0 and surh > 0 and draw_surface then
        local r, g, b, a = rtk.color.rgba(calc.color)
        local sr, sg, sb, sa = rtk.color.mod({ r, g, b, a }, 1.0, 1.0, brightness, amul)

        -- High-contrast hover feedback: brighten button surface on mouse hover
        local base_color = hover and { math.min(1.0, sr * 1.35 + 0.08), math.min(1.0, sg * 1.35 + 0.08), math.min(1.0, sb * 1.35 + 0.08), sa * amul }
          or { sr * cmul, sg * cmul, sb * cmul, sa * amul }

        -- Surface background
        rtk.color.set(base_color)
        rtk.gfx.roundrect(surx, sury, surw, surh, radius, 0, 1)

        -- 1px hairline border for dropdown menus (regular action buttons remain sleek & borderless)
        if is_menu then
          local border_col = hover and (theme.colors.border_focus or "#60a5fa") or (theme.colors.border_card or "#33374c")
          rtk.color.set(border_col)
          rtk.gfx.roundrect(surx, sury, surw, surh, radius, 1, 1)
        end
      elseif calc.bg then
        rtk.color.set(calc.bg)
        rtk.gfx.roundrect(x, y, calc.w, calc.h, radius, 0, 1)
      end

      -- Modern chevron for OptionMenu dropdowns
      if is_menu then
        local arrow_x = x + calc.w - 14
        local arrow_y = y + math.floor((calc.h - 4) / 2)
        local chevron_col = hover and (theme.colors.text_accent or "#60a5fa") or (theme.colors.text_dim or "#94a3b8")
        rtk.color.set(chevron_col)
        -- Crisp, modern downward chevron vector (V-shape)
        gfx.line(arrow_x, arrow_y, arrow_x + 4, arrow_y + 4)
        gfx.line(arrow_x + 1, arrow_y, arrow_x + 4, arrow_y + 3)
        gfx.line(arrow_x + 4, arrow_y + 4, arrow_x + 8, arrow_y)
        gfx.line(arrow_x + 4, arrow_y + 3, arrow_x + 7, arrow_y)
      elseif calc.icon then
        self:_draw_icon(x + pre.ix, y + pre.iy, hover, alpha)
      end

      if calc.label then
        self:setcolor(hover and (calc.textcolor_hover or "#ffffff") or textcolor, alpha)
        -- Pixel-perfect vertical centering
        local target_ly = pre.ly
        if pre.lh and calc.h then
          target_ly = math.floor((calc.h - pre.lh) / 2)
        end
        self._font:draw(self._segments, x + pre.lx, y + target_ly, pre.clipw, pre.cliph)
      end
    end
  end

  -- Measure only the selected label so OptionMenu doesn't reserve excess whitespace for other menu items
  if rtk.OptionMenu then
    function rtk.OptionMenu:_reflow_get_max_label_size(boxw, boxh)
      local segments, lw, lh = rtk.Button._reflow_get_max_label_size(self, boxw, boxh)
      local label_text = self.calc.label or ""
      local w, h = gfx.measurestr(label_text)
      return segments, rtk.clamp(w, lw, boxw), rtk.clamp(h, lh, boxh)
    end
  end

  -- 2. Modern Apple-style Rounded Vector CheckBox
  if rtk.CheckBox then
    function rtk.CheckBox.static._make_icons()
      local w, h = 18, 18
      local wp, hp = 2, 2
      local sz = w - wp * 2

      -- Unchecked state: Charcoal rounded tile with hairline border
      local icon_un = rtk.Image(w, h)
      icon_un:pushdest()
      rtk.color.set "#161822"
      rtk.gfx.roundrect(wp, hp, sz, sz, 4, 0, 1)
      rtk.color.set "#383d54"
      rtk.gfx.roundrect(wp, hp, sz, sz, 4, 1, 1)
      icon_un:popdest()
      rtk.CheckBox.static._icon_unchecked = icon_un

      -- Checked state: Sky-blue vibrant filled tile with crisp pure-white checkmark
      local icon_ck = rtk.Image(w, h)
      icon_ck:pushdest()
      rtk.color.set(theme.colors.text_accent or "#60a5fa")
      rtk.gfx.roundrect(wp, hp, sz, sz, 4, 0, 1)
      rtk.color.set "#ffffff"
      -- Antialiased sharp checkmark vector
      gfx.x = wp + 3
      gfx.y = hp + 7
      gfx.lineto(wp + 5, hp + 10)
      gfx.lineto(wp + 11, hp + 4)
      gfx.x = wp + 3
      gfx.y = hp + 6
      gfx.lineto(wp + 5, hp + 9)
      gfx.lineto(wp + 11, hp + 3)
      icon_ck:popdest()
      rtk.CheckBox.static._icon_checked = icon_ck

      -- Hover state: hollow subtle glowing outline (doesn't overwrite checked state)
      local icon_hv = rtk.Image(w, h)
      icon_hv:pushdest()
      rtk.color.set(theme.colors.text_accent or "#60a5fa")
      rtk.gfx.roundrect(wp, hp, sz, sz, 4, 1, 1)
      icon_hv:popdest()
      rtk.CheckBox.static._icon_hover = icon_hv
      rtk.CheckBox.static._icon_intermediate = icon_ck
    end
    rtk.CheckBox._make_icons()
  end

  -- 3. Modern Entry Caret & Clean Borderless Input with Continuous Blink
  if rtk.Entry then
    function rtk.Entry:_draw_borders(offx, offy, alpha, all)
      if self.calc.border == nil or self.calc.border == false or self.calc.border == "" then
        return
      end
      return rtk.Widget._draw_borders(self, offx, offy, alpha, all)
    end

    -- Continuous animation blink loop
    function rtk.Entry:_blink()
      if self:focused() then
        self._blinking = true
        self:queue_draw()
        rtk.defer(self._blink, self)
      else
        self._blinking = false
      end
    end

    local orig_entry_draw = rtk.Entry._draw
    function rtk.Entry:_draw(offx, offy, alpha, event, clipw, cliph, cltargetx, cltargety, parentx, parenty)
      local calc = self.calc
      local focused = self:focused(event)
      local ret = orig_entry_draw(self, offx, offy, alpha, event, clipw, cliph, cltargetx, cltargety, parentx, parenty)

      -- Smooth, continuous time-based cursor blink cycle
      if focused then
        if not self._blinking then
          self:_blink()
        end

        local cur_time = (reaper and reaper.time_precise and reaper.time_precise()) or (os.clock and os.clock()) or 0
        local blink_on = (cur_time % 1.0) < 0.55 -- On for 550ms, off for 450ms
        local showcursor = (not self._selstart or (self._selend - self._selstart) == 0) and (#calc.value == 0)

        if blink_on and showcursor and self._positions and self._positions[calc.caret] then
          local x = calc.x + offx
          local y = calc.y + offy
          local lp = self._clp or 0
          local tp = self._ctp or 0
          local bp = self._cbp or 0
          local loffset = self._loffset or 0
          local curx = x + self._positions[calc.caret] + lp - loffset
          if curx >= x and curx <= x + calc.w - (self._crp or 0) then
            rtk.color.set(theme.colors.text_accent or "#60a5fa")
            gfx.rect(curx, y + tp + 2, 2, calc.h - tp - bp - 4, 1)
          end
        end
      end

      return ret
    end
  end

  -- 4. Always-visible sleek scrollbar styling for Viewports
  if rtk.Viewport then
    local orig_vp_init = rtk.Viewport.initialize
    function rtk.Viewport:initialize(attrs, ...)
      local ret = orig_vp_init(self, attrs, ...)
      self._scrollbar_alpha_proximity = 0.55
      self._scrollbar_alpha_hover = 0.85
      self._scrollbar_color = theme.colors.text_dim or "#64748b"
      return ret
    end
  end
end

---Attach custom Apple-style rounded rectangle drawing to a widget
---@param widget table
---@param radius number
---@param bg_color? string
---@param border_color? string
---@return table
function ui_draw_helpers.make_rounded_card(widget, radius, bg_color, border_color)
  widget.ondrawpre = function(self, offx, offy, alpha, event)
    local calc = self.calc
    local x = math.floor(calc.x + offx)
    local y = math.floor(calc.y + offy)
    local w = math.floor(calc.w)
    local h = math.floor(calc.h)

    if bg_color then
      rtk.color.set(bg_color)
      rtk.gfx.roundrect(x, y, w, h, radius, 0, 1)
    end
    if border_color then
      rtk.color.set(border_color)
      rtk.gfx.roundrect(x, y, w, h, radius, 1, 1)
    end
    return true
  end
  return widget
end

---Attach custom filled circle dot drawing to a widget
---@param widget table
---@param color string
---@return table
function ui_draw_helpers.make_circle_dot(widget, color)
  widget.ondrawpre = function(self, offx, offy, alpha, event)
    local calc = self.calc
    local radius = math.floor(math.min(calc.w, calc.h) / 2)
    local cx = math.floor(calc.x + offx) + radius
    local cy = math.floor(calc.y + offy) + radius
    rtk.color.set(color)
    gfx.circle(cx, cy, radius, 1, 1)
    return true
  end
  return widget
end

return ui_draw_helpers
