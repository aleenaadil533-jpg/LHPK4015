; q2.asm - attempt 3
; Fix from attempt 2: the array holds dwords (4 bytes each), so the second
; element is at byte offset 1 * 4 = 4, not 1. Offset 1 read the middle of
; two elements and the store corrupted the array.
; Change: divisor now kept in EDX to free up ECX.

section .data
    numbers dd 8, 16, 24, 32        ; array of four unsigned integers

section .text
    global _start

_start:
    mov     eax, [numbers + 4]      ; load second element (16)
    mov     ecx, 4
    mul     ecx                     ; EDX:EAX = 16 * 4 = 64
    mov     edx, 8                  ; divisor
    div     edx                     ; EAX = quotient
    mov     [numbers + 4], eax      ; store quotient back

    mov     ebx, eax                ; return result as exit code
    mov     eax, 1                  ; sys_exit
    int     0x80
