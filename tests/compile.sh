#! /bin/bash
export LUA_PATH=../compiler/?.lua
LCC="lua ../compiler/main.lua"
$LCC test-$1.lua
