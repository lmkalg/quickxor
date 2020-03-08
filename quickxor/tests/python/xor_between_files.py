#!/usr/bin/env python3

from argparse import ArgumentParser

if __name__ == "__main__":
    parser = ArgumentParser()
    parser.add_argument('-f', dest="file_1", help="Path to 1st file")
    parser.add_argument('-g', dest="file_2", help="Path to 2nd file")
    parser.add_argument('-o', dest="output", help="output")
    args = parser.parse_args()
    
    if not args.file_1 or not args.file_2:
        parser.error("Missing arguments")
    
    file_1_bytes = open(args.file_1,'rb').read()
    file_2_bytes = open(args.file_2,'rb').read()

    size_1 = len(file_1_bytes)
    size_2 = len(file_2_bytes)

    bigger_one = file_1_bytes if size_1 >= size_2 else file_2_bytes
    shorter_one = file_2_bytes if size_2 <= size_1 else file_1_bytes

    big_size = max(size_1, size_2)
    small_size = min(size_1, size_2)

    result_bytes = bytearray()

    for i in range(big_size):
        result_bytes.append(shorter_one[i%small_size] ^ bigger_one[i])

    with open(args.output,'wb') as f:
        f.write(result_bytes)













    



