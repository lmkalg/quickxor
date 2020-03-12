#!/usr/bin/env python3
import os
import matplotlib.pyplot as plt
import re 
from argparse import ArgumentParser
from functools import reduce
from collections import namedtuple

Data = namedtuple("Data","user system elapsed cpu")

END_PLACEHOLDER="##FINISH"
QUICKXOR="quickxor"
XOR_IN_C="xor_in_c"
GRAPHICS="graphics"

class DataParserAndPlotter:
    
    def __init__(self):
        self._regex_number_of_tests = re.compile(r"number\s+of\s+tests\s+per\s+test:\s+(\d+)",re.IGNORECASE)
        self._regex_metadata_info = re.compile(r"using\s+([^\s+]+)\s+and\s+([^\s+]+)\s+with\s+([^\s+]+)",re.IGNORECASE)
        self._regex_data_info = re.compile(r"user:\s+(\d+.\d+)\s+system:\s+(\d+.\d+)\s+elapsed:\s+\d:(\d+.\d+)\s+cpu:\s+(\d+)%",re.IGNORECASE)
        self._data = {}
        self._data[QUICKXOR] = {}
        self._data[XOR_IN_C] = {}
    
    def parse(self, filepath):
        """
            Parse the data of the result file 
        """
        with  open(filepath,'r') as f:
            self.content = f.readlines()

        self.number_of_tests = self._parse_number_of_tests(self.content[0])
        i=1
        while self.content[i].strip() != END_PLACEHOLDER:
            filename, key_name, binary = self._parse_metadata_info_from_line(self.content[i])
            if not self._data[binary].get(filename):
                self._data[binary].update({filename:{}})
            if not self._data[binary][filename].get(key_name):
                self._data[binary][filename].update({key_name:[]})
            i+=1
            for test in range(self.number_of_tests):
                user, system, elapsed, cpu = self._parse_data_time_from_line(self.content[i])
                self._data[binary][filename][key_name].append(Data(float(user),float(system),float(elapsed),int(cpu)))
                i+=1

    def _parse_number_of_tests(self, line):
        """
            Function to parse "Number of tests per test: XXXX"
        """
        return int(re.match(self._regex_number_of_tests, line).groups()[0])

    def _parse_data_time_from_line(self, line):
        """
            Function to parse: "User: XXXX System: XXXX Elapsed: XXXX CPU: XXXX"
        """
        return re.match(self._regex_data_info,line).groups()


    def _parse_metadata_info_from_line(self, line):
        """
            Function to parse "Using XXXX and XXXX with XXXXX" and their successive tests cases
        """
        return re.match(self._regex_metadata_info,line).groups()


    def _filename_to_size(self, filename):
        """
            Returns the size based on filename/key filename
        """
        return int(filename[filename.index('_')+1:])

    def _file_size_to_filename(self, size):
        """ 
            Returns the filename based on size
        """
        return "file_{}".format(size)
    
    def _key_size_to_filename(self, size):
        """ 
            Returns the key filename based on size
        """
        return "key_{}".format(size)

    def plot_all(self):
        """
            Function to call all other plots
        """    
        dir_path = os.path.dirname(os.path.realpath(__file__))
        self.graphics_path = os.path.join(dir_path,GRAPHICS)
        if not os.path.exists(self.graphics_path):
            os.makedirs(self.graphics_path)
        self._plot_elapsed_by_file()
        self._plot_elapsed_by_key()
        self._plot_cpu_by_key()
        self._plot_cpu_by_file()

    def _plot_elapsed_by_file(self):
        """
            This plot will show the elapsed time for the quickxor and the xor_in_c with while the
            file size increased (fixed key size)
        """
        fixed_key = "key_2"
        file_size_list = [self._filename_to_size(elem) for elem in list(self._data[QUICKXOR].keys())]
        file_size_list.sort()

        #Get the average elapsed time for each tests for each binary.
        average_elapsed_time_per_file_for_quickxor = []
        for file_size in file_size_list:
            all_tests_data_for_file_and_key = self._data[QUICKXOR][self._file_size_to_filename(file_size)][fixed_key]
            sum_elapsed = sum([elem.elapsed for elem in all_tests_data_for_file_and_key])
            average_elapsed_time_per_file_for_quickxor.append(sum_elapsed/self.number_of_tests)

        average_elapsed_time_per_file_for_xor_in_c = []
        for file_size in file_size_list:
            all_tests_data_for_file_and_key = self._data[XOR_IN_C][self._file_size_to_filename(file_size)][fixed_key]
            sum_elapsed = sum([elem.elapsed for elem in all_tests_data_for_file_and_key])
            average_elapsed_time_per_file_for_xor_in_c.append(sum_elapsed/self.number_of_tests)



        plt.plot(file_size_list, average_elapsed_time_per_file_for_quickxor, label='Quickxor')
        plt.plot(file_size_list, average_elapsed_time_per_file_for_xor_in_c, label='Xor in C')
        plt.legend(loc="upper left")
        plt.title("Elapsed time while increasing size of file (fixed key length {} )".format(self._filename_to_size(fixed_key)))
        plt.ylabel("Elapsed Time (in secs)")
        plt.xlabel("File size (in MB)")
        plt.savefig('{}/elapsed_time_by_file.png'.format(self.graphics_path))
        plt.close()

    def _plot_cpu_by_file(self):
        """
            This plot will show the CPU usage time for the quickxor and the xor_in_c  while the
            file size increased (fixed key size)
        """
        fixed_key = "key_2"
        file_size_list = [self._filename_to_size(elem) for elem in list(self._data[QUICKXOR].keys())]
        file_size_list.sort()

        #Get the average cpu time for each tests for each binary.
        average_cpu_time_per_file_for_quickxor = []
        for file_size in file_size_list:
            all_tests_data_for_file_and_key = self._data[QUICKXOR][self._file_size_to_filename(file_size)][fixed_key]
            sum_cpu = sum([elem.cpu for elem in all_tests_data_for_file_and_key])
            average_cpu_time_per_file_for_quickxor.append(sum_cpu/self.number_of_tests)

        average_cpu_time_per_file_for_xor_in_c = []
        for file_size in file_size_list:
            all_tests_data_for_file_and_key = self._data[XOR_IN_C][self._file_size_to_filename(file_size)][fixed_key]
            sum_cpu = sum([elem.cpu for elem in all_tests_data_for_file_and_key])
            average_cpu_time_per_file_for_xor_in_c.append(sum_cpu/self.number_of_tests)



        plt.plot(file_size_list, average_cpu_time_per_file_for_quickxor, label='Quickxor')
        plt.plot(file_size_list, average_cpu_time_per_file_for_xor_in_c, label='Xor in C')
        plt.legend(loc="upper left")
        plt.title("CPU time while increasing size of file (fixed key length {} )".format(self._filename_to_size(fixed_key)))
        plt.ylabel("CPU Time (in secs)")
        plt.xlabel("File size (in MB)")
        plt.savefig('{}/cpu_time_by_file.png'.format(self.graphics_path))
        plt.close()

    def _plot_cpu_by_key(self):
        """
            This plot will show the CPU usage time for the quickxor and the xor_in_c  while the
            key size increased (fixed file size)
        """
        fixed_file = "file_1024"
        key_size_list = [self._filename_to_size(elem) for elem in list(self._data[QUICKXOR][fixed_file].keys())]
        key_size_list.sort()

        #Get the average cpu time for each tests for each binary.
        average_cpu_time_per_key_for_quickxor = []
        for key_size in key_size_list:
            all_tests_data_for_file_and_key = self._data[QUICKXOR][fixed_file][self._key_size_to_filename(key_size)]
            sum_cpu = sum([elem.cpu for elem in all_tests_data_for_file_and_key])
            average_cpu_time_per_key_for_quickxor.append(sum_cpu/self.number_of_tests)
        
        average_cpu_time_per_key_for_xor_in_c = []
        for key_size in key_size_list:
            all_tests_data_for_file_and_key = self._data[XOR_IN_C][fixed_file][self._key_size_to_filename(key_size)]
            sum_cpu = sum([elem.cpu for elem in all_tests_data_for_file_and_key])
            average_cpu_time_per_key_for_xor_in_c.append(sum_cpu/self.number_of_tests)

        plt.plot(key_size_list, average_cpu_time_per_key_for_quickxor, label='Quickxor')
        plt.plot(key_size_list, average_cpu_time_per_key_for_xor_in_c, label='Xor in C')
        plt.legend(loc="upper left")
        plt.title("CPU time while increasing size of key (fixed file size {})".format(self._filename_to_size(fixed_file)))
        plt.ylabel("CPU Time (in secs)")
        plt.xlabel("Key size (in bytes)")
        plt.savefig('{}/cpu_time_by_key.png'.format(self.graphics_path))
        plt.close()

    def _plot_elapsed_by_key(self):
        """
            This plot will show the elapsed time for the quickxor and the xor_in_c  while the
            key size increased (fixed file size)
        """
        fixed_file = "file_1024"
        key_size_list = [self._filename_to_size(elem) for elem in list(self._data[QUICKXOR][fixed_file].keys())]
        key_size_list.sort()

        #Get the average elapsed time for each tests for each binary.
        average_elapsed_time_per_key_for_quickxor = []
        for key_size in key_size_list:
            all_tests_data_for_file_and_key = self._data[QUICKXOR][fixed_file][self._key_size_to_filename(key_size)]
            sum_elapsed = sum([elem.elapsed for elem in all_tests_data_for_file_and_key])
            average_elapsed_time_per_key_for_quickxor.append(sum_elapsed/self.number_of_tests)
        
        average_elapsed_time_per_key_for_xor_in_c = []
        for key_size in key_size_list:
            all_tests_data_for_file_and_key = self._data[XOR_IN_C][fixed_file][self._key_size_to_filename(key_size)]
            sum_elapsed = sum([elem.elapsed for elem in all_tests_data_for_file_and_key])
            average_elapsed_time_per_key_for_xor_in_c.append(sum_elapsed/self.number_of_tests)

        plt.plot(key_size_list, average_elapsed_time_per_key_for_quickxor, label='Quickxor')
        plt.plot(key_size_list, average_elapsed_time_per_key_for_xor_in_c, label='Xor in C')
        plt.legend(loc="upper left")
        plt.title("Elapsed time while increasing size of key (fixed file size {})".format(self._filename_to_size(fixed_file)))
        plt.ylabel("Elapsed Time (in secs)")
        plt.xlabel("Key size (in bytes)")
        plt.savefig('{}/elapsed_time_by_key.png'.format(self.graphics_path))
        plt.close()

if __name__ == "__main__":
    parser = ArgumentParser()
    parser.add_argument('-f', dest="result_file", help="Path to result file")

    args = parser.parse_args()
    if not args.result_file:
        parser.error("Missing arguments")

    
    data_parser_and_plotter = DataParserAndPlotter()    
    data_parser_and_plotter.parse(args.result_file)
    data_parser_and_plotter.plot_all()



