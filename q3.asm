; q3.asm - attempt 3
; Fix from attempt 2: MUL writes the high half of the product to EDX and
; DIV uses EDX as the high half of the dividend, so EDX cannot hold the
; running sum. The sum now lives in EBX, and EDX is cleared before DIV.
; Change: use the LOOP instruction with ECX as the counter and the index.

section .data
    A   dd 2, 4, 6, 8, 10, 12, 14, 16, 18, 20
    C   dd 4, 6, 8, 10, 12, 14, 16, 18, 20, 22

section .bss
    B   resd 10
    after_B resd 1                  ; next variable in memory

section .text
    global _start

_start:
    mov     ecx, 10                 ; 10 iterations
for_loop:
    mov     esi, ecx                ; i
    mov     eax, [A + esi * 4]      ; A[i]
    mov     edi, 3
    mul     edi                     ; A[i] * 3
    add     eax, 1
    mov     ebx, eax                ; sum = term1

    mov     eax, [C + esi * 4]      ; C[i]
    mov     edi, 2
    mul     edi                     ; C[i] * 2
    add     eax, 1
    add     ebx, eax                ; sum += term2

    mov     eax, [A + esi * 4]
    add     eax, [C + esi * 4]      ; A[i] + C[i]
    xor     edx, edx                ; clear high half of dividend
    mov     edi, 2
    div     edi                     ; (A[i] + C[i]) / 2
    add     ebx, eax                ; sum += term3

    mov     [B + esi * 4], ebx      ; B[i] = sum
    loop    for_loop                ; ecx--, repeat while ecx != 0

    mov     ebx, [B]                ; exit code = B[0]
    mov     eax, 1                  ; sys_exit
    int     0x80
