const std = @import("std");
const Allocator = std.mem.Allocator;
const ByteCode = @import("bytecode.zig").ByteCode;

const Self = @This();

const MEMORY_CELLS = 2048;
var ProgramMemory = [_]u8{0} ** MEMORY_CELLS;

const RuntimeStatus = enum {
    Ok,
    Err,
};

allocator: Allocator,
ip: usize,
mp: usize,
code: []u8,
memory: []u8,

pub fn create(allocator: Allocator, code: []u8) Self {
    return Self{
        .allocator = allocator,
        .ip = 0,
        .mp = 0,
        .code = code,
        .memory = &ProgramMemory,
    };
}

pub inline fn destroy(self: *const Self) void {
    self.allocator.free(self.code);
}

pub fn run(self: *Self) RuntimeStatus {
    self.setCells();

    while (self.ip < self.code.len) {
        const byte = @as(ByteCode, @enumFromInt(self.readByte()));

        switch (byte) {
            .inc => self.memory[self.mp] += 1,
            .dec => self.memory[self.mp] -= 1,

            .incby => {
                const count = self.readByte();
                self.memory[self.mp] += count;
            },
            .decby => {
                const count = self.readByte();
                self.memory[self.mp] -= count;
            },

            .memleft => {
                if (self.mp == 0) {
                    self.mp = self.memory.len - 1;
                } else {
                    self.mp -= 1;
                }
            },

            .memright => {
                self.mp += 1;
                if (self.mp == self.memory.len) {
                    self.mp = 0;
                }
            },

            .memleftby => {
                const count = self.readAsUsize();
                if (self.mp < count) {
                    self.mp = self.memory.len - (0 - count - self.mp);
                } else {
                    self.mp -= count;
                }
            },

            .memrightby => {
                const count = self.readAsUsize();
                self.mp += count;
                if (self.mp >= self.memory.len) {
                    self.mp = self.memory.len - count;
                }
            },

            .jmp => {
                const loc = self.readAsUsize();
                if (self.peekMem() == 0) {
                    self.ip = loc;
                }
            },

            .jnz => {
                const loc = self.readAsUsize();
                if (self.peekMem() != 0) {
                    self.ip = loc;
                }
            },

            .input => {},
            .print => std.debug.print("{c}", .{self.peekMem()}),
        }
    }
    return RuntimeStatus.Ok;
}

inline fn readByte(self: *Self) u8 {
    defer self.ip += 1;
    return self.code[self.ip];
}

inline fn readAsUsize(self: *Self) usize {
    const byte = self.readByte();
    return @as(usize, @intCast(byte));
}

inline fn peekMem(self: *const Self) u8 {
    return self.memory[self.mp];
}

fn setCells(self: *Self) void {
    for (0..MEMORY_CELLS) |i| {
        self.memory[i] = 0;
    }
}
