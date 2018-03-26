#! /bin/bash

source ../build.cfg

pushd ../compiler > /dev/null
./build.sh $TARGET
popd > /dev/null

MYDIR=`pwd`
TARGET=$TARGET/playground

function copy() {
    while [ -n "$1" ]; do
        if [ ${1: -4} == ".lua" ]; then
            if [ $1 -nt $TARGET/${1%.lua}.js ]; then
                echo Compiling $1
                pushd ../compiler > /dev/null
                lua main.lua $LFLAGS $MYDIR/$1 > $TARGET/${1%.lua}.js
                if [ $? != 0 ]; then rm $TARGET/${1%.lua}.js; fi
                popd > /dev/null
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

copy handlebars.lua document.lua storage.lua

copy index.html index.css demo.lua

copy finder.html finder.css finder.lua
copy editor.html editor.css editor.lua
copy console.html console.css console.lua

copy serverdb.php mysql_compat.php
