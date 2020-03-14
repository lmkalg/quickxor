#!/bin/sh

# Constants
NUMBER_OF_TIMES_PER_TEST=10
KEYS=keys
FILES=files
BINARIES=binaries
OUTPUTS=outputs
RESULT_FILE=result.txt
QUICKXOR=quickxor
OTHER_TOOL=other_tool

# Empty file
> $RESULT_FILE
echo -n "Tools being compared: " >> $RESULT_FILE
for tool in `ls $BINARIES`
do
    echo -n "$tool " >> $RESULT_FILE
done
echo >> $RESULT_FILE
echo "Number of tests per test: $NUMBER_OF_TIMES_PER_TEST" >> $RESULT_FILE


for file in `ls $FILES`
do 
    for key in `ls $KEYS`
    do
        for tool in `ls $BINARIES`
        do
            echo "Using $file and $key with $tool" >> $RESULT_FILE
            for times in `seq 1 $NUMBER_OF_TIMES_PER_TEST `
            do 
                time -f "User: %U System: %S Elapsed: %E CPU: %P" $BINARIES/$tool $FILES/$file $KEYS/$key $OUTPUTS/output_q 2>> $RESULT_FILE
                echo
            done
        done
    done
done
rm $OUTPUTS/*
echo "##FINISH" >> $RESULT_FILE
