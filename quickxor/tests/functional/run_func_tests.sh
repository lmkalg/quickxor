set -e
for dir in `ls -d test*`
do
    echo -n "Checking against $dir..." 
    ../../src/asm/quickxor $dir/file $dir/key expected_asm
    diff expected_asm $dir/expected
    echo "[Test OK]"



done
echo "All tests were successfully"
rm expected_asm