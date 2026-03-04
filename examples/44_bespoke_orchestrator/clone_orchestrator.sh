#!/bin/bash

# Get the absolute path to the directory where THIS script is located
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

if [ -z "$1" ]; then
    echo "Usage: $0 <destination_directory>"
    exit 1
fi

# Convert destination to absolute path if it's relative
DEST_INPUT=$1
if [[ "$DEST_INPUT" = /* ]]; then
    DEST="$DEST_INPUT"
else
    DEST="$(pwd)/$DEST_INPUT"
fi

echo "🏗️  Cloning MoonCrust Orchestrator Scaffold to $DEST..."

mkdir -p "$DEST/nodes/generated"

# Copy core files using absolute paths to avoid context issues
cp "$SCRIPT_DIR/backend.lua" "$DEST/"
cp "$SCRIPT_DIR/node_worker.lua" "$DEST/"
cp "$SCRIPT_DIR/main.lua" "$DEST/"
cp "$SCRIPT_DIR/launch.sh" "$DEST/"
cp "$SCRIPT_DIR/run_backend.sh" "$DEST/"
cp "$SCRIPT_DIR/template_graph.json" "$DEST/"
cp "$SCRIPT_DIR/CMakeLists.txt" "$DEST/"
cp -r "$SCRIPT_DIR/nodes/"* "$DEST/nodes/"
cp -r "$SCRIPT_DIR/shaders" "$DEST/"

chmod -R 777 "$DEST/nodes"

echo "✅ Done. You can now launch this version from the project root using:"
echo "./examples/44_bespoke_orchestrator/launch.sh $(realpath --relative-to="$(pwd)" "$DEST")"
