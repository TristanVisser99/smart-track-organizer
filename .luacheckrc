std = "lua54"

-- Maximum cyclomatic complexity and line lengths
max_line_length = 160

-- Exclude third-party vendor libraries from linting
exclude_files = {
  "src/lib/rtk.lua",
  ".git"
}

-- Whitelist REAPER global APIs
globals = {
  "reaper",
  "gfx"
}

-- Allow undefined fields on standard globals for ReaScript
not_globals = {}
