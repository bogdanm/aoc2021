; Based on the template at https://medium.com/geekculture/linux-x86-assembly-hello-world-using-nasm-e235205a9d1e

; *********************************************************************************************************************
; Code section

    global _start                       ; export entry point

    section .text

; Program entry point
_start:
    ; Solve part 1
    mov     rsi, part1_str              ; Write "Part 1: "
    call    puts
    call    solve1                      ; solve the first part, result is in rax
    mov     rsi, cvtbuf
    call    utoa                        ; convert result to a string
    call    puts                        ; and print it
    call    nl

    ; Solve part 2
    mov     rsi, part2_str              ; Write "Part 2: "
    call    puts
    call    solve2                      ; solve the first part, result is in rax
    mov     rsi, cvtbuf
    call    utoa                        ; convert result to a string
    call    puts                        ; and print it
    call    nl

    ; All done
    call    exit

; Solve the first part of the puzzle, return the result in rax.
; Input data is represented as 64-bit integers.
solve1:
    mov     rax, 0                      ; counter
    mov     rcx, 8                      ; current index (i = 1)
    mov     rsi, input                  ; index of first input
solve1loop:
    ; Exit if we reached the end of the array
    cmp     rcx, input_size
    je      solve1done
    ; Load current element and compare with previous element
    mov     rdx, [rsi + rcx]
    cmp     rdx, [rsi + rcx - 8]
    ; Only increment if input[i] > input[i - 1]
    jle     noinc1
    inc     rax
noinc1:
    ; Increment index and repeat
    add     rcx, 8
    jmp     solve1loop
solve1done:
    ret

; Solve the second part of the puzzle, return the result in rax.
solve2:
    mov     rax, 0                      ; solution counter
    ; Start with the current sum (input[0] + input[1] + input[2])
    mov     rbx, [rsi]
    add     rbx, [rsi + 8]
    add     rbx, [rsi + 16]
    mov     rcx, 8                      ; current index (i = 1)
    mov     rsi, input                  ; index of first input
solve2loop:
    ; Exit if reached the end of the array
    ; We're iterating until no more sums can be computed, so stop at input_size - 2 elements
    cmp     rcx, input_size - 16
    je      solve2done
    ; Compute new sum in rdx (new_sum = crt_sum - input[i - 1] + input[i + 2])
    mov     rdx, rbx
    sub     rdx, [rsi + rcx - 8]
    add     rdx, [rsi + rcx + 16]
    cmp     rdx, rbx
    ; Only increment if new_sum > crt_sum
    jle     noinc2
    inc     rax
noinc2:
    ; Update crt_sum t next_sum, increment index and repeat
    mov     rbx, rdx
    add     rcx, 8
    jmp     solve2loop
solve2done:
    ret

; Write the string given in rsi to the screen
puts:
    ; Count the total number of chars in the string, excluding the terminator
    mov     rdx, 0
    mov     rdi, rsi
cntloop:
    ; Read a byte from the string. If we found 0, exit the loop with the string size in rdx
    cmp     byte [rdi], 0
    jz      donecnt
    ; Increment string pointer and string size and repeat
    inc     rdi
    inc     rdx
    jmp     cntloop
donecnt:
    ; At this point rsi has the string and rdx has the string length, so we can call write
    mov     rax, 1                      ; system call for write
    mov     rdi, 1                      ; making file handle stdout
    syscall                             ; invoke write syscall
    ret

; Write a newline to the console
nl:
    mov     rsi, nl_str
    call    puts
    ret

; Invoke the exit syscall to exit the application
exit:
    mov     rax, 60                     ; sys call for exit
    xor     rdi, rdi                    ; exit code 0
    syscall                             ; never returns

; Convert the unsigned number in rax to an ASCIIZ string. Buffer for conversion is in rsi.
utoa:
    push    rsi                         ; original source
    push    rsi                         ; yes, we need to push twice since we're also preserving the original source
    mov     rcx, 10                     ; constant divider
cvtloop:
    ; Divide current number (in eax) by 10. The reminder (in dl) gives the next digit in the number
    mov     rdx, 0                      ; div divides rdx:rax by rcx (10), stores quotient in rax, reminder in rdx
    div     rcx
    ; Convert reminder to ASCII by adding the code for '0' and store it in the buffer
    add     dl, '0'
    mov     [rsi], dl
    inc     rsi
    ; If eax = 0, there's nothing more to convert, otherwise repeat the loop with the quotient (already in eax)
    cmp     eax, 0                      ; more to convert ?
    jnz     cvtloop
cvtdone:
    mov     byte [rsi], 0               ; null terminator
    ; We're not quite done. Due to the way we converted the numnber, its representation is reversed in the output buffer
    ; (its least significat digit is in buffer[0]). So revert the outout buffer in place to get the final representation.
    ; The code below implements the equivalent of this pseudo-C code:
    ; for (rcx = 0, rsi = buffer, rdi = rsi + strlen(buffer) - 1; rcx < strlen(buffer) / 2; rcx ++, rsi ++, rdi --) {
    ;     bl = *rsi;
    ;     bh = *rdi;
    ;     *rsi = bh;
    ;     *rdi = bl;
    ; }
    mov     rdi, rsi
    sub     rdi, 1                      ; rdi = pointer to last char in string
    mov     rdx, rsi
    pop     rsi                         ; restore original buffer pointer (pointer to the first char in string)
    sub     rdx, rsi
    shr     rdx, 1                      ; rdx = actual string length / 2
    mov     rcx, 0                      ; reverse counter
revloop:
    ; Exchange the bytes at [rsi] and [rdi]
    mov     bl, [rsi]
    mov     bh, [rdi]
    mov     [rsi], bh
    mov     [rdi], bl
    ; Are we done processing ?
    inc     rcx                         ; next iteration
    cmp     rcx, rdx
    jz      revdone                     ; done reversing
    ; Increment source, decrement destination, repeat
    inc     rsi
    dec     rdi
    jmp     revloop
revdone:
    pop     rsi                         ; restore original buffer pointer
    ret

; *********************************************************************************************************************
; Readonly data section

    section .rodata

    part1_str: db "Part 1: ", 0
    part2_str: db "Part 2: ", 0
    nl_str: db 0xa, 0

    ; The input data is in a separate file. Each elements in the input must be a qword (64 bits) integer.
    input:
        %include "input.txt"
    input_size: equ ($ - input)         ; input_size is in bytes, not in elements

; *********************************************************************************************************************
; Data section

    . section .data

    cvtbuf: db 20 dup(0)                ; buffer used for converting numbers to strings