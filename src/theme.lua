---@meta

---@class DesignTokens
---@field colors table<string, string>
---@field typography table<string, number>
---@field spacing table<string, number>
---@field borders table<string, string>
local theme = {}

theme.colors = {
  -- Modern Obsidian & Slate Surface Laddering (Linear / FabFilter / Raycast inspired)
  bg_canvas       = "#0b0c10", -- Deep Charcoal Canvas
  bg_surface      = "#13151b", -- Card & Panel Surface (L1)
  bg_surface_elev = "#1a1d26", -- Elevated Card / Hover Surface (L2)
  bg_input        = "#111318", -- Search & Entry Box Surface
  bg_header       = "#161822", -- Pinned Column Header Bar
  bg_row_even     = "#12141c", -- Zebra Striping Even
  bg_row_odd      = "#0e1017", -- Zebra Striping Odd
  bg_row_hover    = "#1e2230", -- Interactive Row Hover Highlight

  -- High-Legibility Typography
  text_primary    = "#f4f6fa", -- Pure Silver-White
  text_secondary  = "#9ca3af", -- Neutral Gray Body
  text_dim        = "#606778", -- Tertiary / Index Numbers
  text_accent     = "#60a5fa", -- Sky-Blue Brand Accent

  -- Hairline Borders & Subtle Glow Rings
  border_card     = "#232738", -- Hairline Card Outline (0.08 alpha look)
  border_active   = "#3b4259", -- Elevated Card Border
  border_glow     = "#60a5fa", -- Brand Focus Glow Ring
  border_focus    = "#ffffff", -- White Focus Highlight

  -- Action Buttons & CTAs
  btn_primary_bg  = "#238636", -- Studio Emerald Action
  btn_primary_fg  = "#ffffff",
  btn_subtle_bg   = "#242735", -- Slate Glass Action
  btn_subtle_fg   = "#c9cedb"
}


-- Modern typography scale & preferred typefaces
theme.typography = {
  font_family     = "Inter, -apple-system, BlinkMacSystemFont, Segoe UI, Roboto, Helvetica Neue, Arial, sans-serif",
  preferred_fonts = { "Inter", "SF Pro Text", "Segoe UI", "Roboto", "Helvetica Neue", "Arial", "Calibri" },
  title_scale     = 1.15,
  heading_scale   = 1.05,
  body_scale      = 0.95,
  caption_scale   = 0.88,
  badge_scale     = 0.85
}


-- Balanced layout spacing
theme.spacing = {
  window_padding  = 12,
  card_padding    = 10,
  row_padding     = 6,
  gap_sm          = 6,
  gap_md          = 10,
  gap_lg          = 12
}

return theme
