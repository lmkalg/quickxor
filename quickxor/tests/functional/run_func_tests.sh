#!/bin/bash

set -e
QUICKXOR_DIR=../../src

# Compiling quickxor
make -C $QUICKXOR_DIR


for dir in `ls -d test*`
do
    echo -n "Checking against $dir..." 
    $QUICKXOR_DIR/quickxor $dir/file $dir/key expected_asm
    diff expected_asm $dir/expected
    echo "[Test OK]"
done
echo "All tests were successfully"
rm expected_asm