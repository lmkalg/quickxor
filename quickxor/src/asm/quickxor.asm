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
    push r10
    push r11
    push r12
    push r13
    push r14
    push r15
    push rbx

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

set_the_final_cut: 
    ; I have discovered that we when the amount of bytes that are goning to be xored en each round + the amount of bytes that are going to be xored in the last 
    ; is less that 16, we were doing invalid reads and writes. Because in the inmedetiately  before last round,  we're reading the content from [r15] with an xmm, 
    ; therefore reading 16 bytes. But, the amount of bytes that were going to be xored + bytes of the last round is less than 16, we were reading out of bounds. 
    ; This part is to avoid doing this! If that condition is met, then, we are going to stop in the previous to the last round
    mov ebx, r9d ; Amount of bytes to be xored in the last round
    add ebx, r14d; Amount of bytes that are going to be xored in each round
    cmp ebx, 16
    jl problematic_case

nice_case: 
    mov ebx, 1
    jmp xor_round

problematic_case: 
    mov r9d, ebx; So, we have to define the new lefovers. 
    mov ebx, 2

xor_round:
    cmp ecx, ebx; if only one round lefts, xor the last round. Otherwise, just perform a simple xor. 
    je do_last_2_xor_rounds
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

do_last_2_xor_rounds:
    xor r12, r12; Will hold the last key.
    movq rax, xmm1; We get the first 8 bytes of the key
    cmp ebx, 1
    je prepare_last_key

do_prev_to_last_xor_round:
    ; I achieved the decision that if we re in this case, the number of bytes of the string that are not yet xored are at least 10. 
    ; Therefore, we can use a R register for this part, and then continue with rest.
    ; The only problem is that if we use here 8 bytes of the key, then we should accomodate the offset for the key again!
    mov rcx, [r15]; Get 8 bytes from the file 
    xor rcx, rax; Perform xor
    mov [r8], qword rcx; Write 8 bytes a
    add r15, 8
    add r8, 8
    sub r9d, 8; We have 8 less leftovers as we write 8 

accomodate_key:
    ; Due to we have used arbitrary 8 bytes from the key, we should re think again the offset of it (just rotate it :) )
    ;Also we have to update the lefovers..! 
    ; we have the amount of lefovers in r9d
    psrldq xmm1, 8 ; Shift the used key! 
    movq r12, xmm1 ; Get the 8 bytes that left from the key. (this has a combination of parts of the key, plus 0's)  [kx|k(len(key-1))|0|0..]
    lea r13, [r14d-8] ; Get the amount of bytes that left from the xmm1 that are actual parts of the key. 
    ; Now, we should grab the first 8 bytes from the original super key, shift it to the rigth: 8 -  the amount of bytes that are actually part of the key and then or it. 
    ; So we will have contigously something like: [kx|k(len(key-1))|k0|k1|k2..]
    
shift_key:
    ; rax stills has the first 8 bytes of the key. 
    cmp r13,0; 
    je prepare_last_key
    shl rax, 8;bits!
    dec r13
    jmp shift_key
;    psrldq xmm1, 8              

prepare_last_key: 
    or r12, rax

do_last_xor_round: 
    cmp r9d, 8
    jg last_round_with_xmm

;====================================================================================
;========================= Operate last round  with R =============================
;====================================================================================

    ; we need to read byte by byte in order not to perform an out of bounds read. 
    ; we know this part is for sure less than 8 bytes! so we can use an R register.
    xor rcx, rcx; Counter for leftover bytes written
    xor rax, rax; Counter for shifts performed
    xor r13, r13; Auxiliary register to do shits
    xor rbx, rbx; Auxiliary register to get byte
    xor r11, r11; Acummulator
    ;pxor xmm9, xmm9; prepare xmm9, auxilary register
    ;pxor xmm10, xmm10; prepare xmm10 accumulator

read_leftover_bytes_byte_by_byte:
    cmp ecx, r9d; Check if we already read all the leftover bytes.
    je do_last_xor
    xor ebx, ebx; Clean auxiliar register
    mov bl, [r15]; Read byte from string
    mov r13, rbx;
    mov eax, ecx; Creates new counter to know how many shifts should be performed for this byte.
    
do_shift_for_lefover_byte:
    cmp eax, 0; Did we finish? 
    je add_leftover_byte_to_acumulator
;    pslldq xmm9, 1 ; shift once
    shl r13, 8; in bits
    dec eax; derement the counter of shifts.
    jmp do_shift_for_lefover_byte

add_leftover_byte_to_acumulator:
    ;por xmm10, xmm9; Add byte to acumulator
    or r11, r13; Add byte to acumulator in correct position
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
    xor r11, r12 ; 

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
    ;movq rbx, xmm10; Download the first qword 
    mov rbx, r11
    xor rcx, rcx; Create counter for amount of written bytes    

write_leftover_bytes:
    cmp ecx, r9d; If we finished writing all leftovers bytes, finish.
    je this_is_the_end
    ;cmp ecx, 8
;    je download_second_qword

write_one_lefotver_byte:
    mov [r8], bl; Write byte in result buffer
    shr rbx, 8 ; in bits!
    inc r8 ; Increment the pointer to the result buffer
    inc ecx; Increment the amount of leftover bytes written
    jmp write_leftover_bytes


;====================================================================================
;========================= Operate last round  with xmm =============================
;====================================================================================


last_round_with_xmm: 
    ; we need to read byte by byte in order not to perform an out of bounds read. 
    ; TODO: This may be improved.. if the amount of bytes is 9, we may first read 8 bytes with an R memory for example.
    xor rcx, rcx; Counter for leftover bytes written
    xor rax, rax; Counter for shifts performed
    pxor xmm9, xmm9; prepare xmm9, auxilary register
    pxor xmm10, xmm10; prepare xmm10 accumulator

read_leftover_bytes_byte_by_byte_xmm:
    cmp ecx, r9d; Check if we already read all the leftover bytes.
    je do_last_xor_xmm
    xor ebx, ebx; Clean auxiliar register
    mov bl, [r15]; Read byte from string
    movd xmm9, ebx; Read byte from string
    mov eax, ecx; Creates new counter to know how many shifts should be performed for this byte.
    
do_shift_for_lefover_byte_xmm:
    cmp eax, 0; Did we finish? 
    je add_leftover_byte_to_acumulator_xmm
    pslldq xmm9, 1 ; shift once
    dec eax; derement the counter of shifts.
    jmp do_shift_for_lefover_byte_xmm

add_leftover_byte_to_acumulator_xmm:
    por xmm10, xmm9; Add byte to acumulator
    inc r15 ; increment the ptr to the string
    inc ecx; increment the counter of leftover read.
    jmp read_leftover_bytes_byte_by_byte_xmm



; =============================================================================
; At this point we have xmm10 with the following structure
; 
; xmm10 = [leftoverbytes|00|..|00]
; 
; =============================================================================

do_last_xor_xmm:
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


write_last_round_xmm:
    movq rbx, xmm10; Download the first qword 
    xor rcx, rcx; Create counter for amount of written bytes    

write_leftover_bytes_xmm:
    cmp ecx, r9d; If we finished writing all leftovers bytes, finish.
    je this_is_the_end
    cmp ecx, 8
    je download_second_qword_xmm

write_one_lefotver_byte_xmm:
    mov [r8], bl; Write byte in result buffer
    shr rbx, 8
    inc r8 ; Increment the pointer to the result buffer
    inc ecx; Increment the amount of leftover bytes written
    jmp write_leftover_bytes_xmm

download_second_qword_xmm:
    psrldq xmm10, 8
    movq rbx, xmm10; Download the second qword
    jmp write_one_lefotver_byte_xmm






; =============================================================================
; =============================================================================
; =============================    END    =====================================
; =============================================================================
; =============================================================================





this_is_the_end:   
    pop rbx
    pop r15
    pop r14
    pop r13
    pop r12
    pop r11
    pop r10
    pop rbp
    ret