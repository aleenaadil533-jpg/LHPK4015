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
