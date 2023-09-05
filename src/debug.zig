const std = @import("std");
const ByteCode = @import("bytecode.zig").ByteCode;

pub fn debug(unit: [:0]const u8, code: []u8) void {
    std.debug.print("=== {s} {d} ===\n", .{ unit, code.len });
    var ip: usize = 0;
    while (ip < code.len) {
        debug_instruction(&ip, code);
    }
}

fn debug_instruction(ip: *usize, code: []u8) void {
    const op = @as(ByteCode, @enumFromInt(code[ip.*]));
    std.debug.print("{d:0>4} | ", .{ip.*});
    switch (op) {
        .inc => simple_instruction(ip, "INC"),
        .dec => simple_instruction(ip, "DEC"),

        .incby => byte_instruction(ip, "INC_BY", code),
        .decby => byte_instruction(ip, "DEC_BY", code),

        .memleft => simple_instruction(ip, "MEM_LEFT"),
        .memright => simple_instruction(ip, "MEM_RIGHT"),

        .memleftby => byte_instruction(ip, "MEM_LEFT_BY", code),
        .memrightby => byte_instruction(ip, "MEM_RIGHT_BY", code),

        .input => simple_instruction(ip, "INPUT"),
        .print => simple_instruction(ip, "PRINT"),

        .jmp => jump_instruction(ip, "JUMP", code),
        .jnz => jump_instruction(ip, "JNZ", code),
    }
}

fn simple_instruction(ip: *usize, label: [:0]const u8) void {
    std.debug.print("{s}\n", .{label});
    ip.* += 1;
}

fn byte_instruction(ip: *usize, label: [:0]const u8, code: []u8) void {
    const location = code[ip.* + 1];
    std.debug.print("{s} {d}\n", .{ label, location });
    ip.* += 2;
}

fn jump_instruction(ip: *usize, label: [:0]const u8, code: []u8) void {
    const location = code[ip.* + 1];
    std.debug.print("{s} {d}\n", .{ label, location });
    ip.* += 2;
}
