#! /bin/bash

LCC="lua main.lua"
TMP=/tmp/Loulabelle-test-$RANDOM
TMP_CORE=${TMP}-core
TMP_JSCR=${TMP}-jscr
TMP_OUT1=${TMP}-out1
TMP_OUT2=${TMP}-out2

function runtest() {
    while [ -n "$1" ]; do

        echo -n "Testing $1 ... "
        pushd ../compiler > /dev/null
        $LCC ../tests/test-$1.lua > $TMP_JSCR
        popd > /dev/null
        cat $TMP_CORE $TMP_JSCR | node > $TMP_OUT1
        lua test-$1.lua > $TMP_OUT2
        dos2unix $TMP_OUT1 > /dev/null
        dos2unix $TMP_OUT2 > /dev/null
        if cmp $TMP_OUT1 $TMP_OUT2; then
            echo OK
        else
            echo FAIL
            exit 0
        fi

        shift
    done
}

function runtest2() {
    while [ -n "$1" ]; do

        echo -n "Testing $1 ... "
        pushd ../compiler > /dev/null
        $LCC ../tests/test-$1.lua > $TMP_JSCR
        popd > /dev/null
        cat $TMP_CORE $TMP_JSCR | node > $TMP_OUT1
        if grep -q -- "--ALL OK--" $TMP_OUT1; then
            echo OK
        else
            echo FAIL
            exit 0
        fi

        shift
    done
}

pushd ../compiler > /dev/null
$LCC core.lua > $TMP_CORE
popd > /dev/null

if [ -n "$1" ]; then
    runtest $1
    exit 0
else
    runtest bits goto math misc pcall \
            string-basic string-format string-regex \
            table-lib vector
    runtest2 coroutine datetime fastcall next-pairs
fi

rm ${TMP}-*
