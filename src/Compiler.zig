const std = @import("std");
const Allocator = std.mem.Allocator;
const ByteList = std.ArrayList(u8);
const ByteCode = @import("bytecode.zig").ByteCode;

const Self = @This();

pub const VERSION = 1;

allocator: Allocator,
source: []u8,
ip: usize,
code: ByteList,

pub const CompilerError = error{
    UnmatchedLoop,
} || Allocator.Error;

pub fn create(allocator: Allocator, source: []u8) Self {
    return Self{
        .allocator = allocator,
        .source = source,
        .ip = 0,
        .code = ByteList.init(allocator),
    };
}

pub inline fn destroy(self: *const Self) void {
    self.allocator.free(self.source);
    self.code.deinit();
}

pub fn compile(self: *Self) CompilerError![]u8 {
    errdefer self.destroy();

    while (self.ip < self.source.len) {
        try self.compileInstruction();
    }
    return try self.code.toOwnedSlice();
}

inline fn isAtEnd(self: *const Self) bool {
    return self.ip >= self.source.len;
}

inline fn peek(self: *const Self) u8 {
    if (self.isAtEnd()) {
        return 0;
    }
    return self.source[self.ip];
}

inline fn advance(self: *Self) void {
    self.ip += 1;
}

inline fn addOp(self: *Self, op: ByteCode) void {
    self.code.append(@as(u8, @intFromEnum(op))) catch std.debug.panic("OOM", .{});
}

inline fn addByOp(self: *Self, op: ByteCode, count: u8) void {
    self.code.append(@as(u8, @intFromEnum(op))) catch std.debug.panic("OOM", .{});
    self.code.append(count) catch std.debug.panic("OOM", .{});
}

inline fn addJump(self: *Self, op: ByteCode, byte: u8) usize {
    self.code.append(@as(u8, @intFromEnum(op))) catch std.debug.panic("OOM", .{});
    self.code.append(byte) catch std.debug.panic("OOM", .{});
    return self.code.items.len - 1;
}

fn compileInstruction(self: *Self) !void {
    switch (self.peek()) {
        '+', '-', '<', '>' => self.tryCompileMany(self.peek()),

        '.' => {
            self.addOp(.print);
            self.advance();
        },

        '[' => try self.compileLoop(),
        else => unreachable,
    }
}

fn charToManyOp(char: u8) ByteCode {
    return switch (char) {
        '+' => .incby,
        '-' => .decby,
        '<' => .memleftby,
        '>' => .memrightby,
        else => unreachable,
    };
}

fn charToOp(char: u8) ByteCode {
    return switch (char) {
        '+' => .inc,
        '-' => .dec,
        '<' => .memleft,
        '>' => .memright,
        else => unreachable,
    };
}

fn tryCompileMany(self: *Self, char: u8) void {
    var count: usize = 0;
    while (self.peek() == char) {
        count += 1;
        self.advance();
    }

    while (count > 0) {
        if (count >= 255) {
            self.addByOp(charToManyOp(char), @as(u8, @intCast(count)));
            count -= 255;
        } else if (count > 2) {
            self.addByOp(charToManyOp(char), @as(u8, @intCast(count)));
            count = 0;
        } else {
            self.addOp(charToOp(char));
            count -= 1;
        }
    }
}

fn compileLoop(self: *Self) CompilerError!void {
    const location = self.addJump(.jmp, 0);
    self.advance();

    while (!self.isAtEnd() and self.peek() != ']') {
        try self.compileInstruction();
    }

    if (self.peek() != ']') {
        std.debug.print("Unmatched loop block\n", .{});
        return CompilerError.UnmatchedLoop;
    }
    self.advance();

    _ = self.addJump(.jnz, @as(u8, @intCast(location - 1)));
    self.code.items[location] = @as(u8, @intCast(self.code.items.len - 1));
}
