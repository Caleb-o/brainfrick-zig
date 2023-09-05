const std = @import("std");
const Allocator = std.mem.Allocator;
const Compiler = @import("Compiler.zig");
const VM = @import("VM.zig");
const debug = @import("debug.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) {
        std.debug.panic("Error: Leaked memory!\n", .{});
    };
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len != 2) {
        std.debug.print("Usage: brainfrick script.bf\n", .{});
        return;
    }

    const fileName = args[1];

    const code = try readOrCompileSource(allocator, fileName);
    var vm = VM.create(allocator, code);
    defer vm.destroy();

    // debug.debug(fileName, code);

    const status = vm.run();
    std.debug.print("Result: {s}\n", .{@tagName(status)});
}

fn getHash(buffer: []const u8) u64 {
    var hash: u64 = 2166136261;
    for (buffer) |byte| {
        hash ^= @as(u64, byte);
        hash *%= 16777619;
    }
    return hash;
}

fn readOrCompileSource(allocator: Allocator, fileName: [:0]const u8) ![]u8 {
    const source = try readFile(allocator, fileName);
    // errdefer allocator.free(source);
    const hash = getHash(source);

    const compiled_file_name = try std.fmt.allocPrintZ(allocator, "{s}c", .{fileName});
    defer allocator.free(compiled_file_name);

    const compiled_file_t = std.fs.cwd().openFile(compiled_file_name, .{});

    if (compiled_file_t) |compiled_file| {
        defer compiled_file.close();

        if (std.fs.File.stat(compiled_file)) |stat| {
            const version = try readU64FromFile(compiled_file);
            const compiled_hash = try readU64FromFile(compiled_file);

            if (version == Compiler.VERSION and hash == compiled_hash) {
                // std.debug.print("Reading from compiled file\n", .{});
                allocator.free(source);
                return try compiled_file.readToEndAlloc(allocator, stat.size - 8);
            }
        } else |_| {}
    } else |_| {}

    var compiler = Compiler.create(allocator, source);
    defer compiler.destroy();

    const code = try compiler.compile();
    errdefer allocator.free(code);

    try writeCompiledFile(compiled_file_name, hash, code);

    return code;
}

fn readU64FromFile(file: std.fs.File) !u64 {
    var num_bytes = [_]u8{0} ** 8;
    var sizen = try file.read(&num_bytes);
    std.debug.assert(sizen == 8);
    return std.mem.readInt(u64, &num_bytes, .Big);
}

fn writeCompiledFile(fileName: [:0]const u8, hash: u64, bytes: []u8) !void {
    const file = try std.fs.cwd().createFile(fileName, .{});
    defer file.close();

    var writer = file.writer();
    try writer.writeInt(u64, Compiler.VERSION, .Big);
    try writer.writeInt(u64, hash, .Big);
    _ = try writer.write(bytes);
}

fn readFile(allocator: Allocator, fileName: [:0]const u8) ![]u8 {
    const file = try std.fs.cwd().openFile(fileName, .{});
    defer file.close();

    return try file.readToEndAlloc(allocator, (try file.stat()).size);
}
