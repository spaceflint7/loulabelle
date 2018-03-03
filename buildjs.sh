#! /bin/bash

TARGET=Loulabelle.js
JSOBJ="\$lua"
# LFLAGS="-o"

pushd compiler > /dev/null
TARGET=../$TARGET

echo "$JSOBJ.preload_chunk('Loulabelle*statestack'," > $TARGET
lua main.lua $LFLAGS statestack.lua | sed 1,1d >> $TARGET

echo "$JSOBJ.preload_chunk('Loulabelle*lexer'," >> $TARGET
lua main.lua $LFLAGS lexer.lua | sed 1,1d >> $TARGET

echo "$JSOBJ.preload_chunk('Loulabelle*parser'," >> $TARGET
lua main.lua $LFLAGS parser.lua | sed 1,1d >> $TARGET

echo "$JSOBJ.preload_chunk('Loulabelle*emitter'," >> $TARGET
lua main.lua $LFLAGS emitter.lua | sed 1,1d >> $TARGET

echo "$JSOBJ.preload_chunk('Loulabelle'," >> $TARGET
lua main.lua $LFLAGS transpiler.lua | sed 1,1d >> $TARGET
