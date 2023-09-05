# brainfrick-zig

A simple compiler + VM for Brainfuck. It compiles each character to an operation, using RLE to compile a series of the same operation when there are 3 or more. The compiler also matches [] to complete loop blocks.

Before compilation, the compiler checks for a file with `.bfc` to see if there's a compiled version of the program. This contains the compiler version, a hash of the original source and the bytecode generated.

If the version and hash matches, it will load the bytecode into the VM and run, otherwise, it will re-compile and generate a new `.bfc` file.

## Sample Code to Bytecode

```
+++.
```

Translates to two operations:

```
INC_BY  3
PRINT
```
