 set -e
 OTHER_TOOLS_DIR=../other_tools_to_compare
 QUICKXOR_DIR=../../src

 # Compilation 
 make -C $QUICKXOR_DIR
 
 for dir in `ls -d test*`
 do
    $QUICKXOR_DIR/quickxor $dir/file $dir/key $dir/expected_asm
    $OTHER_TOOLS_DIR/c/xor_in_c $dir/file $dir/key $dir/expected_c
    python3 $OTHER_TOOLS_DIR/python/xor_between_files.py -f $dir/file  -g $dir/key -o $dir/expected_py

    diff $dir/expected_asm $dir/expected_c
    diff $dir/expected_asm $dir/expected_py

    rm $dir/expected_asm $dir/expected_c
    mv $dir/expected_py $dir/expected

done