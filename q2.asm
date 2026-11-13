; q2.asm - attempt 2
; Fix from attempt 1: MUL/DIV cannot take an immediate operand, so the
; multiplier and divisor are now loaded into registers first.

section .data
    numbers dd 8, 16, 24, 32        ; array of four unsigned integers

section .text
    global _start

_start:
    mov     eax, [numbers + 1]      ; load second element
    mov     ecx, 4
    mul     ecx                     ; EDX:EAX = EAX * 4
    mov     ecx, 8
    div     ecx                     ; EAX = quotient, EDX = remainder
    mov     [numbers + 1], eax      ; store quotient back into second element

    mov     ebx, eax                ; return result as exit code to check it
    mov     eax, 1                  ; sys_exit
    int     0x80
