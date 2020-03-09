#!/bin/bash
set -e

QUICKXOR_DIR=../src/asm
XOR_IN_C_DIR=../src/c
KEYS=keys
FILES=files
BINARIES=binaries
OUTPUTS=outputs

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

echo "[*] Creating random files"
i=128
for j in `seq 1 5`;
do
    dd if=/dev/urandom of=$FILES/file_$i count=$i bs=1M 2> /dev/null
    i=$(($i*2))
done
echo "[+] Done!"

echo "[*] Compiling quickxor"
nasm -f elf64 $QUICKXOR_DIR/quickxor.asm -o $QUICKXOR_DIR/quickxor.o
gcc $QUICKXOR_DIR/quickxor.o $QUICKXOR_DIR/quickxor.c -o $BINARIES/quickxor
echo "[+] Done!"

echo "[*] Compiling xor_in_c"
gcc -O2 $XOR_IN_C_DIR/xor_in_c.c -o $BINARIES/xor_in_c
echo "[+] Done!"

echo "[+] Everything is ready!"


