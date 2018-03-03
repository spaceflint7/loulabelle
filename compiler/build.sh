#! /bin/bash

source ../build.cfg
if [ -n "$1" ]; then
    TARGET=$1
else
    echo "Usage: ./build.sh directory"
    echo "Compiles Loulabelle compiler and core library"
    echo "   into Loulabelle.js and core.js files"
    echo "   in the specified directory"
    echo "Build flags are taken from ../build.cfg"
    exit 1
fi

#
# if need to compile any one of the modules making up
# the compiler, compile all of them, and merge into
# the single file $TARGET/Loulabelle.js
#
# this file is designed to be preloaded via a SCRIPT
# tag, and it is then available to Lua using
#       require "Loulabelle".
# see Loulabelle manual, sections 4 and 6.3, and also
# playground/console.html and playground/console.lua
#

for f in {statestack,lexer,parser,emitter,transpiler}.lua; do

    if [ $f -nt $TARGET/Loulabelle.js ]; then

        echo Compiling compiler

        echo "$JSOBJ.preload_chunk('Loulabelle*statestack'," > $TARGET/Loulabelle.js
        lua main.lua $LFLAGS statestack.lua | sed 1,1d >> $TARGET/Loulabelle.js

        echo "$JSOBJ.preload_chunk('Loulabelle*lexer'," >> $TARGET/Loulabelle.js
        lua main.lua $LFLAGS lexer.lua | sed 1,1d >> $TARGET/Loulabelle.js

        echo "$JSOBJ.preload_chunk('Loulabelle*parser'," >> $TARGET/Loulabelle.js
        lua main.lua $LFLAGS parser.lua | sed 1,1d >> $TARGET/Loulabelle.js

        echo "$JSOBJ.preload_chunk('Loulabelle*emitter'," >> $TARGET/Loulabelle.js
        lua main.lua $LFLAGS emitter.lua | sed 1,1d >> $TARGET/Loulabelle.js

        echo "$JSOBJ.preload_chunk('Loulabelle'," >> $TARGET/Loulabelle.js
        lua main.lua $LFLAGS transpiler.lua | sed 1,1d >> $TARGET/Loulabelle.js

        break
    fi
done

#
# compile the core library
#

if [ core.lua -nt $TARGET/core.js ]; then

    echo Compiling core library

    lua main.lua $LFLAGS core.lua > $TARGET/core.js
fi
