#!/bin/bash
set -e


if [ -z "$1" ]
then
    echo "Misssing Argument. Type -h for help"
    exit 1
else
    if [ $1 == "-h" ]
    then
        echo "Use positional argument to set the name of the tool you want to use for comparision."
        echo "The executable of this tool should be placed in: other_tools_to_compare/name_of_tool/name_of_tool"
        echo "Being 'name_of_tool' the argument provided."
        echo "Example: $0 xor_in_c"
        echo "Also, this tool should receive the parameters in the following order: ./tool_name path_to_file path_to_key path_to_output"
        echo "More details in README.md"
        exit 0
    fi
fi

QUICKXOR_DIR=../../src/
OTHER_TOOL_NAME=$1
OTHER_TOOL=../other_tools_to_compare/$OTHER_TOOL_NAME/$OTHER_TOOL_NAME
KEYS=keys
FILES=files
BINARIES=binaries
OUTPUTS=outputs

if [ ! -f "$OTHER_TOOL" ]; then
    echo "The binary $OTHER_TOOL does not exists" 
    exit 1
fi





echo "[*] Creating dirs.."
mkdir -p $KEYS
mkdir -p $FILES
mkdir -p $BINARIES
mkdir -p $OUTPUTS
echo "[+] Done!"

echo "[*] Creating random keys.."
for i in `seq 1 16`;
do
    dd if=/dev/urandom of=$KEYS/key_$i count=$i bs=1 2> /dev/null
done
echo "[+] Done!"

echo "[*] Creating random files (this may take a few seconds)"
i=128
for j in `seq 1 5`;
do
    dd if=/dev/urandom of=$FILES/file_$i count=$i bs=1M 2> /dev/null
    i=$(($i*2))
done
echo "[+] Done!"

echo "[*] Compiling quickxor"
make -C $QUICKXOR_DIR > /dev/null
echo "[+] Done!"
cp $QUICKXOR_DIR/quickxor $BINARIES

echo "[*] Copiting $OTHER_TOOL_NAME to binaries"
cp $OTHER_TOOL binaries
echo "[+] Done!"

echo "[+] Everything is ready!"


