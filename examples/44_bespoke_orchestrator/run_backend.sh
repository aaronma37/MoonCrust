#!/bin/bash
export LUA_PATH="src/lua/?.lua;src/lua/?/init.lua;;"
luajit examples/44_bespoke_orchestrator/backend.lua
