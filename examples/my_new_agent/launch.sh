#!/bin/bash

# Default target directory
TARGET_DIR=${1:-"examples/44_bespoke_orchestrator"}

# Kill any existing processes on our ports
fuser -k 5555/udp 5556/udp 5557/udp 2>/dev/null

echo "🌌 Launching MoonCrust Orchestrator from: $TARGET_DIR"

# 1. Start Lua Backend in background
./$TARGET_DIR/run_backend.sh $TARGET_DIR &
BACKEND_PID=$!

# 2. Wait for backend to warm up
sleep 1

# 3. Launch MoonCrust Kernel targeting the main.lua in that directory
# We need to pass the directory to Lua so it knows where to load its graph and nodes
export MC_ORCHESTRATOR_DIR=$TARGET_DIR
./build/mooncrust 44 $TARGET_DIR

# Cleanup on exit
kill -9 $BACKEND_PID
echo "Done."
