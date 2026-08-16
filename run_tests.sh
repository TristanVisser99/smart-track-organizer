#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")"
luajit tests/test_smart_track_organizer.lua
luajit tests/test_reaper_adapter.lua
