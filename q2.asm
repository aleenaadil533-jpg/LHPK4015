; =============================================================================
; File:        q2.asm
; Module:      LHPK4015
; Description: Initialises an array of four unsigned 32-bit integers
;              {8, 16, 24, 32}, loads the second element (16), multiplies it
;              by 4 using MUL, divides the product by 8 using DIV, and stores
;              the quotient back into the second element.
;              Expected result: array[1] = (16 * 4) / 8 = 8.
;
; Target:      x86 (32-bit), Linux, NASM syntax
; Build:       nasm -f elf32 -g -F dwarf q2.asm -o q2.o
;              ld -m elf_i386 q2.o -o q2
; Run/check:   ./q2 ; echo $?      -> prints 8 (the stored array[1] value)
;
; Exit codes:  0-255  value stored in array[1] on success (8 expected)
;              250    error: multiplication overflowed 32 bits
;              251    error: divisor is zero
; =============================================================================

; ----------------------------- Constants -------------------------------------
ELEMENT_SIZE    equ 4               ; each element is a 32-bit (dword) integer
TARGET_INDEX    equ 1               ; second element (arrays are zero-indexed)
MULTIPLIER      equ 4
DIVISOR         equ 8

SYS_EXIT        equ 1               ; Linux i386 system call number for exit
ERR_OVERFLOW    equ 250
ERR_DIV_ZERO    equ 251

; ----------------------------- Data ------------------------------------------
section .data
    ; Step 1: array of four unsigned integers, initialised as required.
    numbers     dd 8, 16, 24, 32
    multiplier  dd MULTIPLIER       ; MUL and DIV need a register or memory
    divisor     dd DIVISOR          ; operand, not an immediate value

; ----------------------------- Code ------------------------------------------
section .text
    global _start

_start:
    ; Step 2: load the second element. The address is calculated from the
    ; index rather than hard-coded, so changing TARGET_INDEX is enough to
    ; process a different element.
    mov     eax, [numbers + TARGET_INDEX * ELEMENT_SIZE]    ; EAX = 16

    ; Step 3: unsigned multiply. MUL puts EAX * operand into EDX:EAX.
    ; If the product does not fit in 32 bits, MUL sets CF and OF and the
    ; high half is left in EDX. That case is caught here, so a truncated
    ; value is never used.
    mul     dword [multiplier]                              ; EDX:EAX = 64
    jc      overflow_error

    ; Step 4: unsigned divide. DIV divides the 64-bit value in EDX:EAX by
    ; the operand, putting the quotient in EAX and the remainder in EDX.
    ; EDX is already 0 here, because the overflow check above passed, so
    ; the dividend is exactly the product. Dividing by zero would raise a
    ; CPU exception (#DE) and crash the program, so the divisor is checked
    ; first.
    mov     ecx, [divisor]
    test    ecx, ecx
    jz      divide_by_zero_error
    div     ecx                                             ; EAX = 8, EDX = 0

    ; Step 5: store the quotient back into the same array element.
    mov     [numbers + TARGET_INDEX * ELEMENT_SIZE], eax    ; numbers[1] = 8

    ; Return the stored value as the exit status. Reading it back from
    ; memory, rather than from EAX, proves the store actually happened.
    mov     ebx, [numbers + TARGET_INDEX * ELEMENT_SIZE]
    jmp     exit_program

overflow_error:
    mov     ebx, ERR_OVERFLOW
    jmp     exit_program

divide_by_zero_error:
    mov     ebx, ERR_DIV_ZERO

exit_program:
    mov     eax, SYS_EXIT               ; EBX already holds the exit status
    int     0x80
