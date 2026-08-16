---@meta

---@class PalettesModule
---@field themes table<string, PaletteTheme>
---@field DEFAULT string
local palettes = {}

---@class PaletteTheme
---@field name string
---@field description string
---@field colors table<string, number>

palettes.themes = {
  modern = {
    name = "Modern Studio",
    description = "Vibrant, balanced hues tailored for dark DAW themes",
    colors = {
      drums     = 0xE0564C, -- Punchy Coral Red
      bass      = 0x2E8B57, -- Deep Sea Green
      vocals    = 0x9D65E8, -- Luminous Royal Violet
      guitars   = 0xE0A030, -- Warm Amber Gold
      keys      = 0x3A9BC2, -- Electric Azure Cyan
      synths    = 0x26C6B8, -- Vibrant Mint Teal
      strings   = 0xC96D87, -- Rose Quartz
      brass     = 0xD6A838, -- Brass Ochre
      fx        = 0x4A74F0, -- Cobalt Glow
      returns   = 0x737F8D, -- Slate Grey
      reference = 0x9E9E9E, -- Neutral Silver
      other     = 0x546E7A  -- Charcoal Blue
    }
  },
  pastel = {
    name = "Pastel Soft",
    description = "Calm, low-fatigue tones ideal for long mixing sessions (Nordic inspired)",
    colors = {
      drums     = 0xE06C75, -- Nordic Salmon
      bass      = 0x98C379, -- Sage Herb
      vocals    = 0xC678DD, -- Muted Orchid
      guitars   = 0xE5C07B, -- Dune Sand
      keys      = 0x61AFEF, -- Frost Blue
      synths    = 0x56B6C2, -- Glacier Teal
      strings   = 0xDE98AB, -- Blush Blossom
      brass     = 0xD19A66, -- Apricot Gold
      fx        = 0x7E9CD8, -- Cornflower
      returns   = 0x6C7086, -- Lavender Slate
      reference = 0xA6ADC8, -- Subtext Ice
      other     = 0x7F8C8D  -- Cool Grey
    }
  },
  vintage = {
    name = "Vintage Console",
    description = "Warm analog desk styling (SSL 4000 & Neve 8078 channel strip vibe)",
    colors = {
      drums     = 0xBA3B2A, -- Terracotta Brick
      bass      = 0x3E6B48, -- Console Olive
      vocals    = 0x6F4E8B, -- Vintage Mulberry
      guitars   = 0xB87333, -- Warm Copper
      keys      = 0x386B7B, -- Marine Steel
      synths    = 0x3B7A57, -- Amazon Forest
      strings   = 0x9C5162, -- Bordeaux Wine
      brass     = 0xB58900, -- Analog Gold
      fx        = 0x4A6984, -- Denim Indigo
      returns   = 0x5F6368, -- Neve Fader Slate
      reference = 0x7A7A7A, -- Gunmetal
      other     = 0x50555C  -- Dark Pewter
    }
  },
  neon = {
    name = "Cyber Neon",
    description = "High-energy glowing cyberpunk / synthwave contrast",
    colors = {
      drums     = 0xFF2A6D, -- Neon Magenta
      bass      = 0x05FFA1, -- Electric Mint
      vocals    = 0xA020F0, -- Ultraviolet
      guitars   = 0xFFAA00, -- Cyber Amber
      keys      = 0x00F0FF, -- Cyan Laser
      synths    = 0x00FFAA, -- Fluorescent Aqua
      strings   = 0xFF0080, -- Hot Pink
      brass     = 0xFFE600, -- Electric Lemon
      fx        = 0x3A66FF, -- Hyper Blue
      returns   = 0x8892B0, -- Ghost Grey
      reference = 0xE2E8F0, -- Pure Platinum
      other     = 0x4D5656  -- Deep Graphite
    }
  },
  minimal = {
    name = "Monochrome Slate",
    description = "Understated, matte professional palette with balanced tonal contrast",
    colors = {
      drums     = 0xB04A4A, -- Muted Mahogany
      bass      = 0x4A855E, -- Matte Spruce
      vocals    = 0x7C589C, -- Deep Amethyst
      guitars   = 0xAD7E3B, -- Matte Bronze
      keys      = 0x3D758C, -- Storm Steel
      synths    = 0x3D8C85, -- Deep Sea Foam
      strings   = 0x8C4F62, -- Dusty Plum
      brass     = 0x9E8336, -- Smoked Ochre
      fx        = 0x4F67A6, -- Midnight Navy
      returns   = 0x5C636E, -- Charcoal
      reference = 0x7B828C, -- Graphite
      other     = 0x454A52  -- Slate Charcoal
    }
  }
}

palettes.DEFAULT = "modern"

---Get palette theme by name
---@param name? string
---@return PaletteTheme
function palettes.get(name)
  local key = name or palettes.DEFAULT
  return palettes.themes[key] or palettes.themes[palettes.DEFAULT]
end

---Get RGB color integer for a given category and palette
---@param category_key string
---@param palette_name? string
---@return number
function palettes.get_color(category_key, palette_name)
  local palette = palettes.get(palette_name)
  return palette.colors[category_key] or palette.colors.other
end

---Convert 24-bit RGB integer to hex string (#rrggbb)
---@param rgb number
---@return string
function palettes.rgb_to_hex(rgb)
  return string.format("#%06x", rgb or 0)
end

---Convert 24-bit RGB integer to REAPER native color format
---@param rgb number
---@param reaper_api table
---@return number
function palettes.to_native(rgb, reaper_api)
  local r = math.floor(rgb / 0x10000) % 0x100
  local g = math.floor(rgb / 0x100) % 0x100
  local b = rgb % 0x100
  if reaper_api and reaper_api.ColorToNative then
    return reaper_api.ColorToNative(r, g, b) + 0x1000000
  end
  return rgb
end

return palettes
