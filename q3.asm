; q3.asm - attempt 2
; Fix from attempt 1: x86 addressing cannot use a memory variable as an
; index ([A + [i]*4] is not a valid effective address). The index must be
; in a register, so i is now kept in ESI.
; Change: the running sum is kept in EDX to save a register.

section .data
    A   dd 2, 4, 6, 8, 10, 12, 14, 16, 18, 20
    C   dd 4, 6, 8, 10, 12, 14, 16, 18, 20, 22

section .bss
    B   resd 10

section .text
    global _start

_start:
    xor     esi, esi                ; i = 0
for_loop:
    mov     eax, [A + esi * 4]      ; A[i]
    mov     ecx, 3
    mul     ecx                     ; A[i] * 3
    add     eax, 1
    mov     edx, eax                ; sum = term1

    mov     eax, [C + esi * 4]      ; C[i]
    mov     ecx, 2
    mul     ecx                     ; C[i] * 2
    add     eax, 1
    add     edx, eax                ; sum += term2

    mov     eax, [A + esi * 4]
    add     eax, [C + esi * 4]      ; A[i] + C[i]
    mov     ecx, 2
    div     ecx                     ; (A[i] + C[i]) / 2
    add     edx, eax                ; sum += term3

    mov     [B + esi * 4], edx      ; B[i] = sum
    inc     esi
    cmp     esi, 10
    jb      for_loop

    mov     ebx, [B]                ; exit code = B[0] for a quick check
    mov     eax, 1                  ; sys_exit
    int     0x80
