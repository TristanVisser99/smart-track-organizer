std = "lua54"

-- Exclude third-party vendor libraries, tests mocks, and luarocks trees from linting
exclude_files = {
  "src/lib/rtk.lua",
  ".luarocks",
  ".git",
  "tests"
}

-- Whitelist REAPER global APIs and bundled framework globals
globals = {
  "reaper",
  "gfx",
  "rtk"
}

-- Ignore unused callback arguments and long lines in UI event handlers
unused_args = false
max_line_length = false
ignore = {
  "212", -- unused argument in event handlers
  "611", -- line contains only whitespace
  "631"  -- line is too long
}

-- Allow undefined fields on standard globals for ReaScript
not_globals = {}


