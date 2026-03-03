#!/bin/bash

# Kill any existing processes on our ports
fuser -k 5555/udp 5556/udp 2>/dev/null

echo "🌌 Launching MoonCrust Self-Evolving System..."

# 1. Start Python Backend in background
python3 examples/44_bespoke_orchestrator/backend.py &
BACKEND_PID=$!

# 2. Wait for backend to warm up
sleep 1

# 3. Launch MoonCrust Kernel
./build/mooncrust 44

# Cleanup on exit
kill $BACKEND_PID
echo "Done."
