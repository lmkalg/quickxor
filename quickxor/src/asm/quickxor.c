
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char** argv){
    extern void quickxor();

    FILE* string_file;
    FILE* key_file;
    FILE* result_file;

    // For string 
    string_file = fopen(argv[1], "rb");
    if (string_file == NULL) {
      printf("Error while opening the file.\n");
      exit(1);
    }

    fseek (string_file, 0, SEEK_END);
    long string_len = ftell(string_file);
    fseek (string_file, 0, SEEK_SET);
    char * string_buffer = malloc(string_len);
    if (string_buffer){
        fread(string_buffer, 1, string_len, string_file);
    }
    fclose(string_file);


    // For key 
    key_file = fopen(argv[2], "rb");
    if (key_file == NULL){
      printf("Error while opening the file.\n");
      exit(1);
    }

    fseek (key_file, 0, SEEK_END);
    long key_len = ftell(key_file);
    fseek (key_file, 0, SEEK_SET);
    char * key_buffer = malloc(key_len);
    if (key_buffer){
        fread(key_buffer, 1, key_len, key_file);
    }
    fclose(key_file);

    //For result
    result_file = fopen("result", "wb");
    if (key_file == NULL){
      printf("Error while opening the file.\n");
      exit(1);
    }
    char* res = malloc(string_len);
    if (key_len > 16){
      printf("Sorry! The current version does not support keys longer than 16 bytes.\n");
      exit(1);
    }
    quickxor(&string_buffer, &key_buffer, string_len, key_len, res);
    fwrite(res, 1, string_len, result_file);
    fclose(result_file);
    printf("%s", res);

    return 0;
}