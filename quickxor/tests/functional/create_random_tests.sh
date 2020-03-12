 set -e
 for dir in `ls -d test*`
 do
    ../../src/asm/quickxor $dir/file $dir/key $dir/expected_asm
    ../../src/c/xor_in_c $dir/file $dir/key $dir/expected_c
    python3 ../../src/python/xor_between_files.py -f $dir/file  -g $dir/key -o $dir/expected_py

    diff $dir/expected_asm $dir/expected_c
    diff $dir/expected_asm $dir/expected_py

    rm $dir/expected_asm $dir/expected_c
    mv $dir/expected_py $dir/expected

done