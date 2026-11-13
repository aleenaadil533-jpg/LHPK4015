; =============================================================================
; File:        q3.asm
; Module:      LHPK4015
; Description: Translation of the following C code into x86 assembly:
;
;                unsigned int i, B[10],
;                A[10] = {2,4,6,8,10,12,14,16,18,20},
;                C[10] = {4,6,8,10,12,14,16,18,20,22};
;
;                for (i = 0; i < 10; i++) {
;                    B[i] = (A[i] * 3 + 1) + (C[i] * 2 + 1) + (A[i] + C[i]) / 2;
;                }
;
;              The expression is translated term by term, as written, with no
;              algebraic simplification. All arithmetic is unsigned: MUL, DIV,
;              ADD, with JC checks for carry and JB for comparisons.
;              Expected B = {19, 31, 43, 55, 67, 79, 91, 103, 115, 127}.
;
; Target:      x86 (32-bit), Linux, NASM syntax
; Build:       nasm -f elf32 -g -F dwarf q3.asm -o q3.o
;              ld -m elf_i386 q3.o -o q3
; Run/check:   ./q3 ; echo $?            -> 127 (value of B[9])
;              gdb ./q3, then: catch syscall exit, run, x/10uw &B
;
; Exit codes:  0-249  B[9] on success (127 expected)
;              250    error: unsigned overflow in MUL or ADD
;              251    error: divisor is zero
;              252    error: (A[i] + C[i]) is not exactly divisible
;
; Register use inside the loop:
;   ESI = i (loop index, 0..9)        EBX = running sum for B[i]
;   EAX = working value / MUL & DIV   EDX = high half for MUL / DIV
;   EDI = multiplier or divisor operand
; =============================================================================

; ----------------------------- Constants -------------------------------------
ARRAY_LEN       equ 10              ; number of elements, also the loop bound
ELEMENT_SIZE    equ 4               ; unsigned int = 32-bit dword

A_MULTIPLIER    equ 3               ; A[i] * 3
C_MULTIPLIER    equ 2               ; C[i] * 2
TERM_ADDEND     equ 1               ; the "+ 1" in the first two terms
DIVISOR         equ 2               ; (A[i] + C[i]) / 2

SYS_EXIT        equ 1               ; Linux i386 exit system call
ERR_OVERFLOW    equ 250
ERR_DIV_ZERO    equ 251
ERR_REMAINDER   equ 252

; ----------------------------- Data ------------------------------------------
section .data
    A   dd 2, 4, 6, 8, 10, 12, 14, 16, 18, 20
    C   dd 4, 6, 8, 10, 12, 14, 16, 18, 20, 22
    i   dd 0                        ; C loop variable, kept in step with ESI

section .bss
    B   resd ARRAY_LEN              ; result array, filled by the loop

; ----------------------------- Code ------------------------------------------
section .text
    global _start

_start:
    ; for (i = 0; ...
    ; The index is kept in a register because x86 addressing can only scale
    ; a register, not a memory variable. It is copied to [i] on each pass,
    ; so the C variable i also exists in memory.
    xor     esi, esi                ; i = 0

for_loop:
    mov     [i], esi

    ; ---- Term 1: (A[i] * 3 + 1) ------------------------------------------
    ; MUL multiplies EAX by its operand and puts the 64-bit result in
    ; EDX:EAX. CF is set if the product does not fit in 32 bits.
    mov     eax, [A + esi * ELEMENT_SIZE]
    mov     edi, A_MULTIPLIER
    mul     edi                     ; EDX:EAX = A[i] * 3
    jc      overflow_error
    add     eax, TERM_ADDEND        ; + 1
    jc      overflow_error          ; unsigned ADD overflow sets CF
    mov     ebx, eax                ; sum = term1 (EBX is not touched by MUL/DIV)

    ; ---- Term 2: (C[i] * 2 + 1) ------------------------------------------
    mov     eax, [C + esi * ELEMENT_SIZE]
    mov     edi, C_MULTIPLIER
    mul     edi                     ; EDX:EAX = C[i] * 2
    jc      overflow_error
    add     eax, TERM_ADDEND        ; + 1
    jc      overflow_error
    add     ebx, eax                ; sum += term2
    jc      overflow_error

    ; ---- Term 3: (A[i] + C[i]) / 2 ---------------------------------------
    ; DIV divides the 64-bit value EDX:EAX, so EDX must be cleared first.
    ; Otherwise the high half of an earlier MUL would become part of the
    ; dividend.
    mov     eax, [A + esi * ELEMENT_SIZE]
    add     eax, [C + esi * ELEMENT_SIZE]   ; A[i] + C[i]
    jc      overflow_error
    xor     edx, edx                ; high half of dividend = 0
    mov     edi, DIVISOR
    test    edi, edi                ; a zero divisor would raise #DE and crash
    jz      divide_by_zero_error
    div     edi                     ; EAX = quotient, EDX = remainder
    test    edx, edx                ; the task guarantees A[i] + C[i] is even,
    jnz     remainder_error         ; so a remainder means bad input data
    add     ebx, eax                ; sum += term3
    jc      overflow_error

    ; ---- B[i] = sum ------------------------------------------------------
    mov     [B + esi * ELEMENT_SIZE], ebx

    ; ... i < 10; i++)
    ; ESI counts up from 0 and the loop exits when it reaches 10, so the
    ; body runs exactly 10 times (i = 0..9). The unsigned JB matches the
    ; unsigned type of i.
    inc     esi
    cmp     esi, ARRAY_LEN
    jb      for_loop
    mov     [i], esi                ; i = 10 after the loop, as in C

    ; Success: return the last element, read back from memory.
    mov     ebx, [B + (ARRAY_LEN - 1) * ELEMENT_SIZE]
    jmp     exit_program

overflow_error:
    mov     ebx, ERR_OVERFLOW
    jmp     exit_program

divide_by_zero_error:
    mov     ebx, ERR_DIV_ZERO
    jmp     exit_program

remainder_error:
    mov     ebx, ERR_REMAINDER

exit_program:
    mov     eax, SYS_EXIT           ; EBX holds the exit status
    int     0x80
