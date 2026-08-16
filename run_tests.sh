#!/usr/bin/env bash
set -e

cd "$(dirname "$0")"

# Detect available Lua interpreter (lua, lua5.4, lua5.3, luajit)
LUA_BIN=""
for candidate in lua lua5.4 lua5.3 luajit; do
    if command -v "$candidate" >/dev/null 2>&1; then
        LUA_BIN="$candidate"
        break
    fi
done

if [ -z "$LUA_BIN" ]; then
    echo "❌ Error: No Lua interpreter found on PATH (checked lua, lua5.4, lua5.3, luajit)."
    exit 1
fi

echo "========================================"
echo " Running Tests using: $LUA_BIN"
echo "========================================"

FAILED=0

for test_file in tests/test_*.lua; do
    if [ -f "$test_file" ]; then
        echo ""
        echo "▶ Running $test_file..."
        if "$LUA_BIN" "$test_file"; then
            echo "✔ $test_file passed."
        else
            echo "❌ $test_file failed!"
            FAILED=1
        fi
    fi
done

echo ""
if [ $FAILED -eq 0 ]; then
    echo "========================================"
    echo "  ALL TEST SUITES PASSED SUCCESSFULLY! "
    echo "========================================"
    exit 0
else
    echo "========================================"
    echo "  SOME TESTS FAILED!                    "
    echo "========================================"
    exit 1
fi
