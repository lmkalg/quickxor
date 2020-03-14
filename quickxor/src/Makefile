CC=gcc
NASM=nasm
NFLAGS= -felf64 -g -F dwarf
PROGRAM_NAME=quickxor


all: quickxor.o
	$(CC) quickxor.c quickxor.o -o $(PROGRAM_NAME)

quickxor.o: quickxor.asm
	$(NASM) $(NFLAGS) quickxor.asm 

clean:
	rm quickxor.o $(PROGRAM_NAME)

