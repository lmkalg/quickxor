# Quickxor

What is it? A fast and easy to use XOR tool written in x86 assembly using XMM registers! 
Much faster than usual tools. Really useful for CTF's!

# Limitations
The only limitation of this tool is that the key size cannot be greater than 16 bytes! 
WHY? 
Because of the way it works. It tries to fit the key as much times as possible inside a 16 bytes register. 

# Install 
Only two tools will be required:
1. gcc
2. nasm

```bash
$> cd quickxor/src/
$> make
```
If you want to install it system wide, after the previous two commands:
```
$> sudo make install
```

# Usage

Usage is very easy:
```bash 
quickxor <path_to_file> <path_to_key> <path_to_output>
```

# Performance / Benchmarking tests performed.

To see some actual benchmarking tests please go to [my blogpost](https://lmkalg.github.io/#tiny_tools/quickxor/)

# Want to test it against other tools? 

Besides **quickxor** itself, a set of testcases has been shipped:

## Functional 
Functional test cases ensure that the tool is running as expected. If you want to try adding some new code to the assembly or change some lines, then afterwards you can quickly ensure the tool still works.
To run these tests: 

```bash
$> quickxor/tests/functional/run_func_tests.sh
```

## Functional - Memory
Do to we are coding in assembler, the way we manage the memory is crucial. There are a set of tests that ensure that neither invalid read/writes access nor leaks are being produced. 
To run these tests:

**Valgrind** required

```bash
$> quickxor/tests/functional/
```

## Benchmarking
Some benchmarking """""""framework"""""""  was developed to let you do benchmarking tests against other tools. 
To so, first get into the corresponding directory
```bash
$> cd quickxor/tests/benchmarking/
```
Here you will find the first important script: **prepare_test_cases.sh**. This script will create some files and keys to use as arguments to test.
However, this script will require you to provide a tool to compare against.  
To do so, you'll need to place the binary inside the diretory **quickxor/tests/other_tools_to_compare** using the name of the tool as directory. 
Unfortunately, this tool should follow the same order for the parameters as **quickxor**, or you can develop a ""**proxy**"".  Let's see 2 examples. 

### Comparing against a binary tool without a proxy

As example, the tool **xor_in_c** has be shipped. This is a binary tool, written in C, which follows the same order for parameters as **quickxor** does.
The only requirement, is that this tool should be compiled before executing the **prepare_test cases.sh** script. So: 
```
$> cd quickxor/tests/other_tools_to_compare/xor_in_c/
$> make 
```

please take into account that the directory and the name of the binary are the same (in this case **xor_in_c**)

Once this action is performed, we can create the cases by running:
```bash
$> ./prepare_test_cases.sh xor_in_c
```

### Comparing against a tool with a proxy

If your tool is not a binary or if it receives parameters in different order, or any other reason, you can create a ""**proxy**"" like the **python** example. 
If you go to **other_tools_to_compare** directory, you will find a python dir. This folder contains a python script called  **xor_between_files**, and a bash script called **python**. In this case the latter is the **proxy**, and here is its code: 

```bash
#!/bin/bash
python3 ../../other_tools_to_compare/python/xor_between_files.py -f $1 -g $2 -o $3
```
As you can see, it is just a file that could be executed, and will call the real tool (also reordering the parameters if needed)
Take into account that using a proxy may affect the performance. 

In this example, you would have to call the script like: 
```bash
$> ./prepare_test_cases.sh xor_in_c python
```

### Running the benchmarking tests

Once the test cases were created and the binaries were compiler or prepared (quickxor and the tool you want to compare) it's time to execute the test. To do so:
```
$> ./run_test_cases.sh
```
All the output will go to the **result.txt** file. 

### Parsing the tests

Once the script finishes, the result.txt will hold all the output of the script. In order to get some useful graphics to make comparisions, there is a python script that will do all the job for you. 
As it uses libraries that are not installed in the system by default (matplotlib), the creation of a virtualenv is suggested:
```
$> mkvirtualenv -p python3 quickxor
$> pip install -r requirements.txt
$> python parser_results.py -f result.txt
```
After it finishes, you'll find some useful graphics in the **graphics** directory!


# Feedback
Feedback is ALWAYS! welcome. Either as pull requests, or as a private message. Don't hesitate to do it!


@lmkalg




