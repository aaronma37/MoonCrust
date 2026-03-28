#!/bin/bash

# Ensure we're in the project root
cd "$(dirname "$0")/.."

echo "🚀 MoonCrust: Scanning all examples for Vulkan structural issues..."
echo "----------------------------------------------------------------"

for main_lua in examples/*/main.lua; do
    echo "🔍 Checking $main_lua..."
    # Run the binary with --lint and exit immediately (simulate by killing it or checking for errors)
    # Since our linter prints to stdout, we can use grep to find warnings/errors.
    # Note: We don't want to actually RUN the example (which might block), so we just scan the file using our Lua linter logic.
    
    # Use the mooncrust binary which supports ULL and has all the required globals
    ./build/mooncrust "$main_lua" --lint 2>&1 | grep -E "WARNING|Error"
done

echo "----------------------------------------------------------------"
echo "✅ Scan complete."
