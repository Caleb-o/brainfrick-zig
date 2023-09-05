# brainfrick-zig

A simple compiler + VM for Brainfuck. It compiles each character to an operation, using RLE to compile a series of the same operation when there are 3 or more. The compiler also matches [] to complete loop blocks.

## Sample Code to Bytecode

```
+++.
```

Translates to two operations:

```
INC_BY  3
PRINT
```
