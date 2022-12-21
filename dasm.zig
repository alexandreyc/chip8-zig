const std = @import("std");
const c8 = @import("./c8.zig");

const print = std.debug.print;
const cwd = std.fs.cwd();

fn usage(name: []const u8) void {
    print("Usage: {s} <rom-file>\n", .{name});
}

const Rom = struct {
    filepath: []const u8,
    size: u64,
    rom: [c8.ram_size]u8,

    // TODO(alexandre): built-in assets (aka font set) should be loaded too.

    fn load(filepath: []const u8) !Rom {
        const file = try cwd.openFile(filepath, .{ .mode = std.fs.File.OpenMode.read_only });
        defer file.close();

        const stat = try file.stat();
        if (stat.size == 0)
            return error.FileEmpty;
        if (stat.size > c8.max_rom_size)
            return error.FileTooBig;

        var rom: [c8.ram_size]u8 = [1]u8{0} ** c8.ram_size;
        const nread = try file.readAll(rom[c8.rom_offset .. c8.rom_offset + stat.size]);
        if (nread != stat.size)
            return error.FileReading;

        return Rom{
            .filepath = filepath,
            .size = stat.size,
            .rom = rom,
        };
    }

    fn fetch(self: Rom, addr: u16) u16 {
        std.debug.assert(addr + 1 < c8.rom_offset + self.size);
        const msb: u16 = self.rom[addr];
        const lsb: u16 = self.rom[addr + 1];
        return msb << 8 | lsb;
    }

    // TODO(alexandre): read https://en.wikipedia.org/wiki/Control-flow_graph to better
    // formalize the algorithm.
    fn dasm(self: Rom, allocator: std.mem.Allocator, writer: anytype) !void {
        var pc: u16 = c8.rom_offset;
        var visited = [1]bool{false} ** c8.ram_size;
        var stack = std.ArrayList(u16).init(allocator);
        defer stack.deinit();

        try stack.append(pc);
        while (stack.items.len > 0) {
            pc = stack.pop();

            while (pc + 1 < c8.rom_offset + self.size and !visited[pc]) {
                const opcode = c8.Opcode.decode(self.fetch(pc)) orelse {
                    pc += 2;
                    continue;
                };

                visited[pc] = true;

                switch (opcode) {
                    .ret => break,
                    .call => |nnn| {
                        try stack.append(pc + 2);
                        pc = nnn;
                        std.debug.assert(pc + 1 < c8.rom_offset + self.size);
                    },
                    .sexkk, .sexy, .snexkk, .snexy, .sknpx, .skpx => {
                        pc += 2;
                        try stack.append(pc + 2);
                        std.debug.assert(pc + 1 < c8.rom_offset + self.size);
                    },
                    .jp => |nnn| {
                        pc = nnn;
                        std.debug.assert(pc + 1 < c8.rom_offset + self.size);
                    },
                    // Impossible to know the destination jump address without
                    // running the ROM because this address depends on register V0.
                    .jpnnn => break,
                    else => pc += 2,
                }
            }
        }

        pc = c8.rom_offset;
        while (pc + 1 < c8.rom_offset + self.size) : (pc += 2) {
            const dword = self.fetch(pc);
            if (visited[pc]) {
                const opcode = c8.Opcode.decode(dword) orelse return c8.Error.IllegalOpcode;
                try opcode.print(pc, writer);
            } else {
                try writer.print("0x{X:0>4}: DATA 0x{X:0>4}\n", .{ pc, dword });
            }
        }
    }
};

pub fn main() !void {
    // Creates memory allocator.
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Parses command-line arguments.
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    if (args.len < 2) {
        usage(args[0]);
        return; // TODO(alexandre): returns exit code 0 whereas we need != 0
    }

    const stdout = std.io.getStdOut();
    for (args) |arg, i| {
        if (i == 0) continue;

        // Loads ROM file and performs some sanity checks.
        std.log.info("disassembling {s}", .{arg});
        const rom = try Rom.load(arg);
        try rom.dasm(allocator, stdout.writer());
    }
}
