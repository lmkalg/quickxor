#include <time.h>
#include <stdio.h>
#include <stdlib.h>

FILE* open_file(const char* _filepath, const char* flags){
    FILE* _file = fopen(_filepath, flags);
    if (_file == NULL) {
      printf("Error while opening the file.\n");
      exit(1);
    }
    return _file;
}

long get_length(FILE * _file){
    fseek (_file, 0, SEEK_END);
    long _file_len = ftell(_file);
    fseek (_file, 0, SEEK_SET);
    return _file_len;
}

char* read_file_and_return_buffer(FILE* _file, long _file_len ){
    char* _file_buffer = malloc(_file_len);
    if (_file_buffer){
        fread(_file_buffer, 1, _file_len, _file);
    }
    return _file_buffer;
}


int main(int argc, char** argv){
    FILE* string_file, *key_file, *result_file;
    long string_len, key_len, result_len;
    char* string_buffer, *key_buffer, *result_buffer;

    // For string 
    string_file = open_file(argv[1],"rb");
    string_len = get_length(string_file);
    string_buffer = read_file_and_return_buffer(string_file, string_len);
    fclose(string_file);


    // For key 
    key_file = open_file(argv[2],"rb");
    key_len = get_length(key_file);
    key_buffer = read_file_and_return_buffer(key_file, key_len);
    fclose(key_file);

    if (key_len > 16){
      printf("Sorry! The current version does not support keys longer than 16 bytes.\n");
      exit(1);
    }
    
    // Operation
    result_len = string_len;
    result_buffer = malloc(result_len);
    int i = 0;
    for(i=0; i < string_len; i++){
        result_buffer[i] = key_buffer[i%key_len] ^ string_buffer[i];
    }


    // For result
    result_file = open_file(argv[3], "wb");
    fseek (result_file, 0, SEEK_SET);
    fwrite(result_buffer, 1, result_len, result_file);
    fclose(result_file);
    
    free(string_buffer);
    free(key_buffer);
    free(result_buffer);
    
    return 0;
}