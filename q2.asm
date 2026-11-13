; q2.asm - attempt 1
; Goal: numbers[1] = (16 * 4) / 8 = 8
; Plan: load the 2nd element, mul by 4, div by 8, store back.

section .data
    numbers dd 8, 16, 24, 32        ; array of four unsigned integers

section .text
    global _start

_start:
    mov     eax, [numbers + 4]      ; load second element (16)
    mul     4                       ; multiply by 4
    div     8                       ; divide by 8
    mov     [numbers + 4], eax      ; store quotient back

    mov     eax, 1                  ; sys_exit
    mov     ebx, 0
    int     0x80
