package.path = "src/?.lua;src/lib/?.lua;" .. package.path

local function assert_eq(actual, expected, message)
  if actual ~= expected then
    error(string.format("%s: expected '%s', got '%s'", message or "Assertion failed", tostring(expected), tostring(actual)))
  end
end

-- Mock complete REAPER & GFX environments including font, image allocation, mouse, and wheel states
_G.reaper = setmetatable({
  time_precise = function() return 0.0 end,
  defer = function(fn) end,
  GetResourcePath = function() return "/tmp" end,
  GetOS = function() return "Other" end,
  get_action_context = function() return false, "/tmp/script.lua", 0, 0, 0, 0, "" end,
  GetMainHwnd = function() return 0 end,
  GetAppVersion = function() return "7.0" end,
  get_ini_file = function() return "/tmp/reaper.ini" end,
  ThemeLayout_GetLayout = function(type, idx) return true, "256" end,
  my_getViewport = function(l, t, r, b, minl, mint, maxr, maxb, want_work) return 0, 0, 1920, 1080 end,
  JS_Window_GetClientSize = function(hwnd) return true, 800, 600 end,
  JS_Window_GetRect = function(hwnd) return true, 0, 0, 800, 600 end,
  JS_Window_Find = function(title, exact) return 1 end,
  new_array = function(tbl, size)
    local data = type(tbl) == "table" and tbl or {}
    local arr = {
      _data = data,
      table = function(self) return data end,
      clear = function(self) data = {} end,
      resize = function(self, s) end
    }
    return arr
  end,
  CountTracks = function(proj) return 2 end,
  GetTrack = function(proj, idx) return "track_" .. tostring(idx) end,
  GetTrackName = function(tr) return true, "Test Track" end,
  IsTrackSelected = function(tr) return false end,
  TrackFX_GetCount = function(tr) return 0 end,
  GetSetMediaTrackInfo_String = function(tr, key, val, set) return true, "" end,
  SetMediaTrackInfo_Value = function(tr, key, val) end,
  Undo_BeginBlock = function() end,
  Undo_EndBlock = function(desc, flag) end,
  PreventUIRefresh = function(v) end,
  TrackList_AdjustWindows = function() end,
  UpdateArrange = function() end
}, {
  __index = function(t, k)
    return function() return 0 end
  end
})

_G.gfx = setmetatable({
  init = function() end,
  quit = function() end,
  set = function() end,
  rect = function() end,
  triangle = function() end,
  setimgdim = function(idx, w, h) end,
  loadimg = function(idx, file) return 0 end,
  blit = function(idx, scale, rot) end,
  setfont = function(idx, fontname, size, flags) end,
  measurestr = function(str) return #tostring(str or "") * 8, 16 end,
  clienttoscreen = function(x, y) return 0, 0 end,
  screentoclient = function(x, y) return 0, 0 end,
  showmenu = function(str) return 3 end,
  getchar = function() return -1 end,
  getdropfile = function(idx) return false, nil end,
  dest = -1,
  mouse_cap = 0,
  mouse_wheel = 0,
  mouse_hwheel = 0,
  mouse_x = 0,
  mouse_y = 0,
  w = 800,
  h = 600
}, {
  __index = function(t, k)
    return function() return 0 end
  end
})

local has_rtk, rtk = pcall(require, "rtk")
assert_eq(has_rtk, true, "RTK library loads successfully in test environment")

local dummy_icon = {
  w = 16,
  h = 16,
  density = 1.0,
  draw = function() end,
  refresh_scale = function() end,
  clone = function(self) return self end,
  recolor = function(self) return self end
}

-- Pre-populate CheckBox & OptionMenu static icons with valid dimensions for headless testing
if rtk and rtk.CheckBox then
  rtk.CheckBox.static._icon_unchecked = dummy_icon
  rtk.CheckBox.static._icon_checked = dummy_icon
  rtk.CheckBox.static._icon_intermediate = dummy_icon
  rtk.CheckBox.static._icon_hover = dummy_icon
end

if rtk and rtk.OptionMenu then
  rtk.OptionMenu.static._icon = dummy_icon
end

local ui_rtk = require("ui_rtk")
assert_eq(type(ui_rtk.launch), "function", "ui_rtk exposes launch function")

-- 1. Test constructing window, widgets, and full GUI layout execution
local function test_rtk_window_instantiation()
  local window = rtk.Window{
    title = "Test Window",
    w = 600,
    h = 400
  }
  assert_eq(window ~= nil, true, "RTK window instantiates")

  local vbox = rtk.VBox{ spacing = 2 }
  local viewport = rtk.Viewport{ child = vbox }
  assert_eq(viewport ~= nil, true, "Viewport with child instantiates correctly")

  -- Test full launch invocation (non-blocking)
  local ran, err = pcall(function()
    ui_rtk.launch(rtk, _G.reaper)
  end)
  assert_eq(ran, true, "ui_rtk.launch executes with 0 runtime errors: " .. tostring(err))
  print("ok - rtk_ui_execution_and_widgets")
end

-- 2. Test interactive OptionMenu popup menu building and selection
local function test_option_menu_interaction()
  local menu_data = {
    { "Modern Studio", id = "modern" },
    { "Pastel Soft", id = "pastel" },
    { "Vintage Console", id = "vintage" },
    { "Cyber Neon", id = "neon" },
    { "Monochrome Slate", id = "minimal" }
  }

  local opt = rtk.OptionMenu{
    menu = menu_data,
    selected = "vintage"
  }
  assert_eq(opt.selected_id, "vintage", "Selected ID is vintage")
  assert_eq(opt.selected_item.label, "Vintage Console", "Selected item label is Vintage Console")

  -- Test NativeMenu string compilation (the exact function that threw the nil concat error)
  local native_menu = rtk.NativeMenu(menu_data)
  local menustr, items = native_menu:_build_menustr(native_menu._order)
  assert_eq(type(menustr), "string", "Native menu string compiled to string")
  assert_eq(#items, 5, "Native menu parsed 5 items")
  assert_eq(items[3].label, "Vintage Console", "Item 3 is Vintage Console")

  -- Test opening NativeMenu with mock gfx.showmenu
  local future = native_menu:open(100, 100)
  assert_eq(type(future), "table", "Native menu returns rtk.Future object")
  assert_eq(type(future.done), "function", "Future exposes done callback")
  print("ok - rtk_option_menu_popup_open")
end



test_rtk_window_instantiation()
test_option_menu_interaction()
print("\nUI component test suite passed.")

