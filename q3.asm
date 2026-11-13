; q3.asm - attempt 4
; Fix from attempt 3: LOOP counts ECX down from 10 to 1, so using it as
; the index processed i = 10..1. It read A[10]/C[10] beyond the arrays,
; wrote B[10] past the end of B, and never wrote B[0]. The index is now a
; separate register (ESI) counting 0..9, exactly like the C for loop.

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
    mov     edi, 3
    mul     edi                     ; A[i] * 3
    add     eax, 1
    mov     ebx, eax                ; sum = A[i]*3 + 1

    mov     eax, [C + esi * 4]      ; C[i]
    mov     edi, 2
    mul     edi                     ; C[i] * 2
    add     eax, 1
    add     ebx, eax                ; sum += C[i]*2 + 1

    mov     eax, [A + esi * 4]
    add     eax, [C + esi * 4]      ; A[i] + C[i]
    xor     edx, edx
    mov     edi, 2
    div     edi                     ; (A[i] + C[i]) / 2
    add     ebx, eax                ; sum += (A[i] + C[i]) / 2

    mov     [B + esi * 4], ebx      ; B[i] = sum
    inc     esi                     ; i++
    cmp     esi, 10                 ; i < 10 ?
    jb      for_loop

    mov     ebx, [B + 9 * 4]        ; exit code = B[9]
    mov     eax, 1                  ; sys_exit
    int     0x80
