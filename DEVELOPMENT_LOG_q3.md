# Development log: q3.asm

**Task:** translate the following C into x86 assembly. The expression must not be simplified, all arithmetic must be unsigned, the division must use `div`, and the loop must run exactly 10 times.

```c
for (i = 0; i < 10; i++)
    B[i] = (A[i] * 3 + 1) + (C[i] * 2 + 1) + (A[i] + C[i]) / 2;
```

**Expected result:** B = {19, 31, 43, 55, 67, 79, 91, 103, 115, 127}. The first value is (2·3+1) + (4·2+1) + (2+4)/2 = 7 + 9 + 3 = 19.

**Environment:** x86 32-bit, Linux, NASM.

```
nasm -f elf32 -g -F dwarf q3.asm -o q3.o
ld -m elf_i386 q3.o -o q3
./q3 ; echo $?                          # exit code = B[9]
gdb: catch syscall exit / run / x/10uw &B
```

## Attempt 1 (build error)

The loop variable `i` was kept in memory, as in C, and used directly as the array index: `[A + [i] * 4]`.

```
$ nasm -f elf32 -g -F dwarf q3.asm -o q3.o
q3.asm:21: error: expression syntax error
q3.asm:27: error: expression syntax error
q3.asm:33: error: expression syntax error
q3.asm:34: error: expression syntax error
q3.asm:40: error: expression syntax error
```

**Cause:** an x86 effective address can only be built from a base register plus a scaled index register plus a displacement. A memory operand cannot be nested inside another memory operand.
**Next step:** hold `i` in a register (ESI) and index with `[A + esi*4]`.

## Attempt 2 (runtime crash)

```
$ ./q3 ; echo $?
Floating point exception (core dumped)
136
(gdb) run
Program received signal SIGFPE, Arithmetic exception.
(gdb) x/10uw &B
0  0  0  0  0  0  0  0  0  0      <- crashed on the first iteration
```

**Cause:** the running sum was kept in EDX, but EDX is used implicitly by both instructions:
- `mul` overwrites EDX with the high half of the product, which destroyed term 1.
- `div` treats EDX:EAX as the 64-bit dividend. With EDX = 9 (term 2), the dividend was 9·2³² + 6. Its quotient when divided by 2 does not fit in 32 bits, so the CPU raised a divide error (#DE), which Linux reports as SIGFPE.

**Next step:** keep the sum in EBX, which `mul` and `div` never touch, and clear EDX before `div`.

## Attempt 3 (wrong result and out-of-bounds write)

This attempt switched to the `loop` instruction, using ECX as both the counter and the index.

```
$ ./q3 ; echo $?
0
(gdb) x/10uw &B
0  31  43  55  67  79  91  103  115  127     <- B[0] never written
(gdb) x/1uw &after_B
16                                            <- variable after B overwritten
```

**Cause:** `loop` counts ECX *down* from 10 to 1, so the loop body ran for i = 10, 9, …, 1 rather than 0 to 9. This had three effects:
- B[0] was never computed.
- A[10] and C[10] were read from beyond the end of the arrays.
- B[10] was written past the end of B, overwriting the next variable with the value 16.

**Next step:** use a separate index that counts up from 0 to 9, with `inc` / `cmp` / `jb`, exactly as the C `for` loop does.

## Attempt 4 (correct output, but edge cases fail)

```
$ ./q3 ; echo $?
127
(gdb) x/10uw &B
19  31  43  55  67  79  91  103  115  127     <- correct, 10 iterations
```

Edge-case testing, each made by changing one input value:

| Test | Change | Result |
|---|---|---|
| Overflow | A[0] = 0x60000000 | B[0] = 1342177292, wrong with no warning (`mul` and `add` overflow ignored) |
| Odd sum | A[0] = 3 | B[0] = 22, the remainder is dropped with no warning |
| Divisor 0 | divisor = 0 | `Floating point exception`, exit 136 |

The code also hard-codes values such as 3, 2, 1, 10 and 4.
**Next step:** check CF after every `mul` and `add`, check for a zero divisor and for a non-zero remainder, replace the hard-coded values with named constants, and document the register use.
