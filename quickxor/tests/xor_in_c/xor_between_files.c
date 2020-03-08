#include <time.h>
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
    
    // 
    char * bigger; 
    char * shorter;
    int big_size;
    int short_size;

    if (string_len > key_len){
        bigger = string_buffer;
        shorter = key_buffer;
        big_size = string_len;
        short_size = key_len;
    }
    else{
        bigger = key_buffer;
        shorter = string_buffer;
        big_size = key_len;
        short_size = string_len;
    }

    int i = 0;
     clock_t t;
    t= clock();
    
    for(i=0; i < big_size;i++){
        res[i] = shorter[i%short_size] ^ bigger[i];
    }
    t= clock() -t ;

    fwrite(res, 1, string_len, result_file);
    double time_taken = ((double)t)/CLOCKS_PER_SEC;
    printf("The program took %f seconds to execute", time_taken);
    fclose(result_file);

    return 0;
}