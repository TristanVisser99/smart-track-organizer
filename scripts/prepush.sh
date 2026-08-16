#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$ROOT_DIR"

echo "=========================================="
echo "  Smart Track Organizer — Pre-Push Check  "
echo "=========================================="

# 1. Run Tests Suite
echo ""
echo "▶ Running test suite..."
if [ -x "./run_tests.sh" ]; then
    ./run_tests.sh
else
    bash ./run_tests.sh
fi

if [ $? -ne 0 ]; then
    echo "❌ Tests failed! Push aborted."
    exit 1
fi

# 2. Run Luacheck if available
if command -v luacheck &> /dev/null; then
    echo ""
    echo "▶ Running Luacheck..."
    luacheck src/ "Smart Track Organizer.lua"
    if [ $? -ne 0 ]; then
        echo "❌ Luacheck lint errors found! Push aborted."
        exit 1
    fi
fi


# 3. Run Selene if available
if command -v selene &> /dev/null; then
    echo ""
    echo "▶ Running Selene linter..."
    selene .
    if [ $? -ne 0 ]; then
        echo "❌ Selene lint errors found! Push aborted."
        exit 1
    fi
fi

# 4. Run StyLua formatting check if available
if command -v stylua &> /dev/null; then
    echo ""
    echo "▶ Checking code formatting with StyLua..."
    stylua --check .
    if [ $? -ne 0 ]; then
        echo "❌ StyLua format check failed! Run 'stylua .' to format. Push aborted."
        exit 1
    fi
fi

echo ""
echo "=========================================="
echo "  ✅ ALL QUALITY GATES PASSED! READY TO PUSH "
echo "=========================================="
exit 0
