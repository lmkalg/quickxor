#!/usr/bin/env python3
import os
import matplotlib.pyplot as plt
import re 
from argparse import ArgumentParser
from functools import reduce
from collections import namedtuple

Data = namedtuple("Data","user system elapsed cpu")
CPU = "cpu"
ELAPSED = "elapsed"
END_PLACEHOLDER="##FINISH"
QUICKXOR="quickxor"
GRAPHICS="graphics"
KEY = "key"
FILE = "file"

class DataParserAndPlotter:
    
    def __init__(self):
        self._regex_number_of_tests = re.compile(r"number\s+of\s+tests\s+per\s+test:\s+(\d+)",re.IGNORECASE)
        self._regex_metadata_info = re.compile(r"using\s+([^\s+]+)\s+and\s+([^\s+]+)\s+with\s+([^\s+]+)",re.IGNORECASE)
        self._regex_data_info = re.compile(r"user:\s+(\d+.\d+)\s+system:\s+(\d+.\d+)\s+elapsed:\s+\d:(\d+.\d+)\s+cpu:\s+(\d+)%",re.IGNORECASE)
        self._data = {}
    
    def _get_names_of_tools(self, line):
        """
           Gets the name of tools: "Tools being compared: X  Y "
        """     
        tools = line.split(":")[1].strip().split(" ")
        self._data[tools[0]] = {}
        self._data[tools[1]] = {}


    def parse(self, filepath):
        """
            Parse the data of the result file 
        """
        with  open(filepath,'r') as f:
            self.content = f.readlines()
        i = 0
        self._get_names_of_tools(self.content[i])
        i+=1
        self.number_of_tests = self._parse_number_of_tests(self.content[i])
        i+=1
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

    def _get_test_data_by_argument(self, tool, arg, arg_size, fixed_value):
        """
            Return corresponding tested data based on the argument type provided
        """
        if arg == FILE:
            return self._data[tool][self._file_size_to_filename(arg_size)][fixed_value]
        elif arg == KEY:
            return self._data[tool][fixed_value][self._key_size_to_filename(arg_size)]

    def _get_argument_size_list_by_argument(self, arg):
        """
            Return corresponding size list based on the argument type provided
        """
        any_tool = list(self._data.keys())[0]
        if arg == FILE:
            return [self._filename_to_size(elem) for elem in list(self._data[any_tool].keys())]
        elif arg == KEY:
            any_file = list(self._data[any_tool].keys())[0]
            return [self._filename_to_size(elem) for elem in list(self._data[any_tool][any_file].keys())]


    def _plot_metric_by_argument(self, metric, argument, fixed_value):
        """
            Refactor
        """
        argument_size_list = self._get_argument_size_list_by_argument(argument)
        argument_size_list.sort()

        #Get the average elapsed time for each tests for each binary.
        average_metric_per_arg_by_tool = {}
        for tool in self._data.keys():
            average_metric_per_arg_by_tool.update({tool:[]})

            for argument_size in argument_size_list:
                all_tests_data_for_file_and_key = self._get_test_data_by_argument(tool, argument, argument_size, fixed_value)
                sum_elapsed = sum([getattr(elem, metric) for elem in all_tests_data_for_file_and_key])
                average_metric_per_arg_by_tool[tool].append(sum_elapsed/self.number_of_tests)

            plt.plot(argument_size_list, average_metric_per_arg_by_tool[tool], label=tool)

        secondary_argument = KEY if argument_size == FILE else FILE
        measure = "Mbytes" if argument == FILE else "Bytes"

        plt.legend(loc="upper left")
        plt.title("{} time while increasing size of {} (fixed {} size {} )".format(metric, argument, secondary_argument, self._filename_to_size(fixed_value)))
        plt.ylabel("{} Time (in secs)".format(metric))
        plt.xlabel("{} size (in {})".format(argument, measure))
        plt.savefig('{}/{}_time_by_{}.png'.format(self.graphics_path, metric, argument))
        plt.close()

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
            This plot will show the elapsed time for the quickxor and the other_tool with while the
            file size increased (fixed key size)
        """
        self._plot_metric_by_argument(ELAPSED, FILE, "key_2")
        

    def _plot_cpu_by_file(self):
        """
            This plot will show the CPU usage time for the quickxor and the other_tool  while the
            file size increased (fixed key size)
        """
        self._plot_metric_by_argument(CPU, FILE, "key_2")


    def _plot_cpu_by_key(self):
        """
            This plot will show the CPU usage time for the quickxor and the other_tool  while the
            key size increased (fixed file size)
        """
        self._plot_metric_by_argument(CPU, KEY, "file_1024")

    def _plot_elapsed_by_key(self):
        """
            This plot will show the elapsed time for the quickxor and the other_tool  while the
            key size increased (fixed file size)
        """
        self._plot_metric_by_argument(ELAPSED, KEY, "file_1024")
     

if __name__ == "__main__":
    parser = ArgumentParser()
    parser.add_argument('-f', dest="result_file", help="Path to result file")

    args = parser.parse_args()
    if not args.result_file:
        parser.error("Missing arguments")

    
    data_parser_and_plotter = DataParserAndPlotter()    
    data_parser_and_plotter.parse(args.result_file)
    data_parser_and_plotter.plot_all()



