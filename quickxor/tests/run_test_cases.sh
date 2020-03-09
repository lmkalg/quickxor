# Constants
NUMBER_OF_TIMES_PER_TEST=1
KEYS=keys
FILES=files
BINARIES=binaries
OUTPUTS=outputs
RESULT_FILE=result.txt
QUICKXOR=quickxor
XOR_IN_C=xor_in_c

# Empty file
echo "" > $RESULT_FILE
echo  "Doing $NUMBER_OF_TIMES_PER_TEST tests per test" >> $RESULT_FILE


for file in `ls $FILES`
do 
    for key in `ls $KEYS`
    do
        echo "Using $file and $key with $QUICKXOR" >> $RESULT_FILE
        for times in `seq 1 $NUMBER_OF_TIMES_PER_TEST `
        do 
            time -f "User: %U System: %S Elapsed: %E CPU: %P" $BINARIES/$QUICKXOR $FILES/$file $KEYS/$key $OUTPUTS/output_q 2>> $RESULT_FILE
        done

        echo "Using $file and $key with $XOR_IN_C" >> $RESULT_FILE
        for times in `seq 1 $NUMBER_OF_TIMES_PER_TEST `
        do 
            time -f "User: %U System: %S Elapsed: %E CPU: %P" $BINARIES/$XOR_IN_C $FILES/$file $KEYS/$key $OUTPUTS/output_c 2>> $RESULT_FILE
        done
    done
done