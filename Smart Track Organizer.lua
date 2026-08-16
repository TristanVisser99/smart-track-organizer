-- @description Smart Track Organizer Pro
-- @author Group 3
-- @version 2.0.0

-- @about
--   Professional DAW Session Organizer for Cockos REAPER.
--   Automatically classifies, colors, formats, sorts, and groups tracks with
--   an interactive modern studio dashboard (built on bundled rtk).
-- @provides
--   [main] Smart Track Organizer.lua
--   src/smart_track_organizer_core.lua
--   src/lexicon.lua
--   src/palettes.lua
--   src/theme.lua
--   src/reaper_adapter.lua
--   src/ui_draw_helpers.lua
--   src/ui_state.lua
--   src/ui_components.lua
--   src/ui_rtk.lua
--   src/ui_native.lua
--   src/lib/rtk.lua

local script_file = ({ reaper.get_action_context() })[2] or ""
local script_path = script_file:match "^(.*)[/\\]" or "."
package.path = script_path .. "/src/?.lua;" .. script_path .. "/src/lib/?.lua;" .. package.path

local has_rtk, rtk = pcall(require, "rtk")
local ui_rtk = require "ui_rtk"
local ui_native = require "ui_native"

local function main()
  if not reaper or not reaper.CountTracks then
    error "This script must be run inside REAPER."
  end

  if has_rtk and rtk and rtk.Window then
    ui_rtk.launch(rtk, reaper)
  else
    ui_native.launch(reaper)
  end
end

main()
