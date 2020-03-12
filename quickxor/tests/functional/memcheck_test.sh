for dir in `ls -d test*`
do
    echo -n "Mem checking against $dir..." 
    valgrind --log-file=valgrind.output ../../src/asm/quickxor $dir/file $dir/key expected_asm
    
    leaks=`grep -ic 'no leaks are possible' valgrind.output`
    invalid_read=`grep -ic 'invalid read' valgrind.output` 
    invalid_write=`grep -ic 'invalid write' valgrind.output` 
    
    if [ $leaks != 0 -a $invalid_read != 1 -a $invalid_write != 1 ]
    then
        echo "[Test OK]"
    else
        echo "[Test ERROR]"
        exit 1
    fi
done
echo "All tests were successfully"
rm valgrind.output
rm expected_asm
