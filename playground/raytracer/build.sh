#! /bin/bash

# here we build a standalone version of the raytracer.
# another version of the raytracer is in the playground.

source ../../build.cfg

MYDIR=`pwd`
LFLAGS=-o
TARGET=$TARGET/ray2
COMPILER=../../compiler
LCC="lua $COMPILER/main.lua $LFLAGS"

function copy() {
    while [ -n "$1" ]; do
        if [ ${1: -4} == ".lua" ]; then
            if [ $1 -nt $TARGET/${1%.lua}.js ]; then
                echo Compiling $1
                $LCC $1 > $TARGET/${1%.lua}.js
                if [ $? != 0 ]; then rm $TARGET/${1%.lua}.js; fi
            fi
        else
            if [ $1 -nt $TARGET/$1 ]; then
                echo Copying $1
                cp $1 $TARGET
            fi
        fi
        shift
    done
}

if [ $COMPILER/core.lua -nt $TARGET/core.js ]; then
    echo Compiling core library
    $LCC $COMPILER/core.lua > $TARGET/core.js
    if [ $? != 0 ]; then rm $TARGET/core.js; fi
fi

copy index.html driver.lua tracer.lua worker.js
copy vector.lua light.lua sphere.lua group.lua
