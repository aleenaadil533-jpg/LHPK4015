; q2.asm - attempt 4
; Fix from attempt 3: DIV divides the 64-bit value EDX:EAX, so EDX is part
; of the dividend. Putting the divisor (8) in EDX made the dividend
; 8:64 = 0x0000000800000040, whose quotient does not fit in 32 bits, and
; the CPU raised a divide error (#DE -> SIGFPE). The divisor now uses ECX
; and EDX keeps the high half of the MUL result (0).

section .data
    numbers dd 8, 16, 24, 32        ; array of four unsigned integers

section .text
    global _start

_start:
    mov     eax, [numbers + 4]      ; load second element (16)
    mov     ecx, 4
    mul     ecx                     ; EDX:EAX = 64, EDX = 0
    mov     ecx, 8
    div     ecx                     ; EAX = 64 / 8 = 8, EDX = 0
    mov     [numbers + 4], eax      ; store quotient back

    mov     ebx, eax                ; return result as exit code
    mov     eax, 1                  ; sys_exit
    int     0x80
