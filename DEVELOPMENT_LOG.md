# Development log: q2.asm

**Task:** initialise `numbers` = {8, 16, 24, 32}, load the second element, multiply it by 4 with `mul`, divide by 8 with `div`, and store the quotient back. The expected value of `numbers[1]` is **8**.

**Environment:** x86 32-bit, Linux, NASM.

```
nasm -f elf32 -g -F dwarf q2.asm -o q2.o
ld -m elf_i386 q2.o -o q2
./q2 ; echo $?
```

The program returns the stored value as its exit code. The array is checked in gdb with `x/4uw &numbers`.

## Attempt 1 (build error)

The first draft passed the multiplier and divisor to `mul` and `div` directly as constants.

```
$ nasm -f elf32 -g -F dwarf q2.asm -o q2.o
q2.asm:13: error: invalid combination of opcode and operands
q2.asm:14: error: invalid combination of opcode and operands
```

**Cause:** `mul` and `div` only accept a register or memory operand. They do not accept an immediate value.
**Next step:** load 4 and 8 into a register before each instruction.

## Attempt 2 (wrong result: array corrupted)

The program assembles and runs, but the exit code is 0 instead of 8.

```
$ ./q2 ; echo $?
0
(gdb) p/x $ebx
$2 = 0x8000000
(gdb) x/16xb &numbers
0x804a000 <numbers>:  0x08 0x00 0x00 0x00 0x08 0x00 0x00 0x00
0x804a008:            0x18 0x00 0x00 0x00 0x20 0x00 0x00 0x00
```

**Cause:** `[numbers + 1]` is a byte offset, but each element is a 4-byte dword. The load therefore read bytes 1 to 4, which span two elements: 0x10000000. That value went through the multiply and divide to become 0x08000000, which was then written back across the boundary between elements 0 and 1.
**Next step:** address the second element at byte offset 1 × 4 = 4.

## Attempt 3 (runtime crash)

```
$ ./q2 ; echo $?
Floating point exception (core dumped)
136
(gdb) run
Program received signal SIGFPE, Arithmetic exception.
(gdb) x/4uw &numbers
0x804a000 <numbers>:  8  16  24  32     <- the store never happened
```

**Cause:** the divisor was placed in EDX, but `div` divides the 64-bit value in EDX:EAX. The dividend therefore became 0x00000008_00000040, and the quotient of that divided by 8 does not fit in 32 bits. The CPU raised a divide error (#DE), which Linux reports as SIGFPE.
**Next step:** use ECX for the divisor and leave EDX holding the high half of the `mul` result, which is 0.

## Attempt 4 (correct result, but edge cases fail)

```
$ ./q2 ; echo $?
8
(gdb) x/4uw &numbers
0x804a000 <numbers>:  8  8  24  32     <- correct
```

Edge-case testing showed this version is still fragile.

| Test | Change | Result |
|---|---|---|
| Divide by zero | divisor = 0 | `Floating point exception`, exit 136 (crash) |
| Overflow | multiplier = 0x20000000 | exit 0, `numbers[1]` = 1073741824 (silently wrong) |

The program also hard-codes values such as `+ 4`, 4 and 8 directly in the instructions instead of naming them.
**Next step:** add a divisor-zero check and a `mul` overflow check (CF), replace the hard-coded values with named constants, and document each step.
