#!/bin/sh

TARGET=$PWD
echo $TARGET
cd ../../luaradio/docs/refman/
REFMAN_DIVS=1 ldoc -c refman.ld --filter refman.filter ../../radio > $TARGET/0.reference-manual.md
