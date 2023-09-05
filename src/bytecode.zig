pub const ByteCode = enum(u8) {
    inc,
    dec,
    incby,
    decby,
    memleft,
    memright,
    memleftby,
    memrightby,
    input,
    print,
    jmp,
    jnz,
};
