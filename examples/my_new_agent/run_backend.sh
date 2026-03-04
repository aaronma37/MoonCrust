#!/bin/bash
TARGET_DIR=${1:-"examples/44_bespoke_orchestrator"}
export LUA_PATH="src/lua/?.lua;src/lua/?/init.lua;./$TARGET_DIR/?.lua;;"
luajit $TARGET_DIR/backend.lua $TARGET_DIR
