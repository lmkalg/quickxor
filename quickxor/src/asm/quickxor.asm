; Compilation: nasm -f elf64 quickXOR.asm -o quickxor; ld -o quickxor quickxor.o

; quickXOR(string, key, len_string, len_key)
; len_key <= 16
; RDI = ptr(string)
; RSI = ptr(key)
; RDX = len_string
; RCX = len_key
; r8  = ptr_for_result


section     .text
GLOBAL quickxor


quickxor:  
    ; stack frame and buffer
    push rbp
	mov rbp,rsp

handle_params:    
    mov rdi, [rdi]
    mov rsi, [rsi]
    mov r11d, edx ; ptr to len of string/file
    mov r10d, ecx; ptr to len of key
    

; ====================================================================
; First of all, we are going to set up all the thing for the key.
;
; The key could be any length, therefore have to be careful in the way 
; we read it. That's why we should perform a read byte by byte. 
;
;
; Once we load the byte from memory, we should put the value in the correct
; place of the register. Therefore, we should perform shifts depending on which
; byte we are talking about. 
;
; For example, if the key is: 0xABCDEF, the progression should be:
; xmm10 = [00|..|00|0xAB]
; xmm10 = [00|..|00|0xCD|0xAB]
; xmm10 = [00|..|00|0xEF|0xCD|0xAB]
;
; Then, afterwards we are going to put the key inside the a 16 byte 
; register as much times as possible. As an example, if the key is 4 
; bytes length, then it will fit 4 times inside the register. If it's
; 5 bytes long, it will fit only 3 times. 
;
; ====================================================================


calculate_sizes_for_key:
    xor edx, edx
    mov eax, 0x10
    ; Reference for division: https://www.aldeid.com/wiki/X86-assembly/Instructions/div
    div r10d
    ; edx = 16 % len_key (amount_of_leftover_bytes_in_xmm)
    ; eax = 16 / len_key (times_key_fits_in_xmm)
    mov r12d, edx; r12 = amount_of_leftover_bytes_in_xmm
    mov r13d, eax; r13 = times_key_fits_in_xmm

    pxor xmm10,xmm10; cleaning xmm10 (this will hold always the key)
    pxor xmm9,xmm9; cleaning xmm9 (this will the partial bytes read)
    pxor xmm1, xmm1; cleaning xmm1 (this will be the acumulator, where we are going to put the key multiple times)
    xor rcx,rcx ; Create counter for reading bytes of key.
    mov r15, rsi

read_key_from_mem_byte_by_byte:
    cmp ecx, r10d ; Counter to now when we read all the bytes of the key. 
    je fill_xmm_with_key
    xor ebx, ebx;
    mov bl, [r15];Read byte
    movd xmm9, ebx ; Store byte in xmm9
    mov eax, ecx; Create a new counter. This time to know how many shifts we should make for each byte

do_shifts_for_key:
    cmp eax, 0; Compare the counter to know if we finished
    je write_byte_in_xmm
    pslldq xmm9, 1; Perform shift
    dec eax
    jmp do_shifts_for_key

write_byte_in_xmm:
    por xmm10, xmm9 ; Once we have the byte in the correct place, we can acummulate the result inside xmm10
    inc ecx
    inc r15
    jmp read_key_from_mem_byte_by_byte

fill_xmm_with_key:    
    ;Now we already have the key stored in xmm10. We should replicate it as much as possible inside xmm10 . 
    mov ecx, r13d; Counter for "filling key" cycle. In other words, the amount of times that the key will fill inside the xmm register.

fill_xmm_with_key_cycle:    
    cmp ecx, 1; If we have only one round left, go to the last one. 
    je finish_filling_xmm_with_key

filling_xmm_round:    
    por xmm1, xmm10; fill xmm1 with the key. 
    mov r14d, r10d; r14d = counter of shifts (initially, is the length of the key)

shifting_xmm: 
    ; we cannot shift based on the value of a register. So we need to do it like a cycle.
    cmp r14d, 0 ; compare the counter against 0 
    je continue_filling_xxm_round ; if it is 0, we finished, otherwwhise, we shift one byte.
    pslldq xmm1, 1 ; shift by 1 byte
    dec r14d ; decrement the counter
    jmp shifting_xmm ; continue cycle.

continue_filling_xxm_round:
    ; once the register is already shifted, we can go to the next round of filling xmm with key multitple times.
    dec ecx
    jmp fill_xmm_with_key_cycle

finish_filling_xmm_with_key:
    por xmm1, xmm10 ; last round (without shift).



; =============================================================================
;  At this point xmm1 has multiple times the key inside (as much as possible). 
;  To ease the languange, I'll call this xmm1, the super key.
;  xmm1 = [KEY|...|KEY|LT] where LT is the leftover. len(LT) = r12d
; =============================================================================


; =============================================================================
;  Let's continue setting up the things regarding the string
; =============================================================================


calculate_sizes_for_string:
    mov r14d, 0x10 ; r14d= 16
    sub r14d, r12d ; r14d = amount_of_bytes_to_xor_by_round (16 - amount_of_leftover_bytes_in_xmm)
    xor edx, edx
    mov eax, r11d;  eax = len_string 
    div r14d ; eax = len_string / amount_of_bytes_to_xor_by_round (amount_of_rounds)
    mov r9d, edx; r9d = amount_of_bytes_to_xor_in_last_round
    inc eax ; amount_of_rounds + 1 (always we have at least one more unless len_string % amount_of_bytes_to_xor_by_round = 0)


; =============================================================================
;  CHECKPOINT.  At this point we should remember:
;  * r10d: Holds the length of the key to xor.
;  * r11d: Holds the length of the string to xor.
;  * r12d: Holds the amount of bytes that are not going to be able to be xored in a round (leftovers).
;  * r14d: Holds the amount of bytes that are going to be xored in each round.
;  * r13d: Holds the amount of times that the key fills into an xmm.
;  * xmm1: Holds the super key (key repeated ${r13d} times).
;  * r9d: Holds the amount of bytes to be xored in the last round.
;  * eax: Holds the amount of rounds that will be needed to xor the whole string. 
; =============================================================================

; =============================================================================
; START PERFORMING THE XOR
; =============================================================================

begin_xor:
    mov ecx, eax; create counter with the amount of rounds to perform 
    mov r15, rdi; store the ptr to the string. 

xor_round:
    cmp ecx, 1; if only one round lefts, xor the last round. Otherwise, just perform a simple xor. 
    je do_last_xor_round
    movdqu xmm2, [r15]; Get 16 bytes from the string to xor (We are going to have always 16 bytes to grab here because it is not the last round )
    pxor xmm2, xmm1 ; Perform the xor between 16 bytes of the string and the super key and store the result in xmm2
    movdqu [r8], xmm2; Write down the result in our return buffer.
    add r8, r14 ; Move the pointer to the return buffer the amount of bytes that were REALLY xored (depends on r14d)
    add r15, r14;  Move the pointer to the string the same amount as above. 
    dec ecx; decrease the counter of rounds. 
    jmp xor_round


; =============================================================================
; The last round is the interesting part as we need to be careful with 
; the leftovers from the string. In the way we xored it, the way we write
; it down, etc. 
;
; It's really close to what we did in the first part reading byte by byte the key.
;
; This part is a little bit tricky as we neeed to read byte by byte all the 
; leftovers ones (the ones that are going to be xored in the last round). 
; 
; As we are going to move data from memory to the reg byte by byte, the byte will
; be placed in the least significant part of the reg. Therefore, we should afterwards
; shift the register to the left to put it in the most significant part of the reg. 
; 
; Finally, we should do the same thing for writing it down as we should write 
; byte by byte.
; 
; =============================================================================


do_last_xor_round: 
    ; we need to read byte by byte in order not to perform an out of bounds read. 
    ; TODO: This may be improved.. if the amount of bytes is 9, we may first read 8 bytes with an R memory for example.
    xor rcx, rcx; Counter for leftover bytes written
    xor rax, rax; Counter for shifts performed
    pxor xmm9, xmm9; prepare xmm9, auxilary register
    pxor xmm10, xmm10; prepare xmm10 accumulator

read_leftover_bytes_byte_by_byte:
    cmp ecx, r9d; Check if we already read all the leftover bytes.
    je do_last_xor
    xor ebx, ebx; Clean auxiliar register
    mov bl, [r15]; Read byte from string
    movd xmm9, ebx; Read byte from string
    mov eax, ecx; Creates new counter to know how many shifts should be performed for this byte.
    
do_shift_for_lefover_byte:
    cmp eax, 0; Did we finish? 
    je add_leftover_byte_to_acumulator
    pslldq xmm9, 1 ; shift once
    dec eax; derement the counter of shifts.
    jmp do_shift_for_lefover_byte

add_leftover_byte_to_acumulator:
    por xmm10, xmm9; Add byte to acumulator
    inc r15 ; increment the ptr to the string
    inc ecx; increment the counter of leftover read.
    jmp read_leftover_bytes_byte_by_byte



; =============================================================================
; At this point we have xmm10 with the following structure
; 
; xmm10 = [leftoverbytes|00|..|00]
; 
; =============================================================================

do_last_xor:
    pxor xmm10, xmm1; perform xor

; =============================================================================
; Now we should do the same thing by to write down the result in memory
;
; xmm10 = [leftoverbytesXORED|00|..|00]
;
; In order to write down the result, we are going to store the qudwords inside R 
; registers and then go slowly storing it in memory. 
; 
; Depending on the amount of leftovers, we are going to download the two qwords
; or just one. 
;
; Once we have the qword inside the R register, we are going to write byte by byte.
;  
;
; =============================================================================


write_last_round:
    movq rbx, xmm10; Download the first qword 
    xor rcx, rcx; Create counter for amount of written bytes    

write_leftover_bytes:
    cmp ecx, r9d; If we finished writing all leftovers bytes, finish.
    je this_is_the_end
    cmp ecx, 8
    je download_second_qword

write_one_lefotver_byte:
    mov [r8], bl; Write byte in result buffer
    shr rbx, 8
    inc r8 ; Increment the pointer to the result buffer
    inc ecx; Increment the amount of leftover bytes written
    jmp write_leftover_bytes

download_second_qword:
    psrldq xmm10, 8
    movq rbx, xmm10; Download the second qword
    jmp write_one_lefotver_byte
    
this_is_the_end:   
    pop rbp
    ret