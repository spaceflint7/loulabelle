#! /bin/bash

export LUA_PATH=../Loulabelle/compiler/?.lua
LCC="lua ../Loulabelle/compiler/main.lua -o"
$LCC $1
