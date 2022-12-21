const std = @import("std");
const print = std.debug.print;

pub const ram_size = 4 * 1024; // 4 KiB
pub const rom_offset = 512;
pub const max_rom_size = ram_size - rom_offset;

pub const Error = error{
    IllegalOpcode,
};

const Nibble = u4;

const DoubleNibble = struct {
    x: u4,
    y: u4,
};

const TripleNibble = struct {
    x: u4,
    y: u4,
    z: u4,
};

const NibbleByte = struct {
    x: u4,
    kk: u8,
};

const Twelve = u12;

pub const Opcode = union(enum) {
    sys: Twelve,
    cls: void,
    ret: void,
    jp: Twelve,
    call: Twelve,
    sexkk: NibbleByte,
    snexkk: NibbleByte,
    sexy: DoubleNibble,
    ldxkk: NibbleByte,
    addxkk: NibbleByte,
    ldxy: DoubleNibble,
    orxy: DoubleNibble,
    andxy: DoubleNibble,
    xorxy: DoubleNibble,
    addxy: DoubleNibble,
    subxy: DoubleNibble,
    shrxy: DoubleNibble,
    subnxy: DoubleNibble,
    shlxy: DoubleNibble,
    snexy: DoubleNibble,
    ldnnn: Twelve,
    jpnnn: Twelve,
    rndxkk: NibbleByte,
    drwxyn: TripleNibble,
    skpx: Nibble,
    sknpx: Nibble,
    ldxdt: Nibble,
    ldxk: Nibble,
    lddtx: Nibble,
    ldstx: Nibble,
    addix: Nibble,
    ldfx: Nibble,
    ldbx: Nibble,
    ldix: Nibble,
    ldxi: Nibble,

    pub fn decode(opcode: u16) ?Opcode {
        const nnn: u12 = @truncate(u12, opcode);
        const x: u4 = @truncate(u4, opcode >> 8);
        const y: u4 = @truncate(u4, opcode >> 4);
        const kk: u8 = @truncate(u8, opcode);
        const n: u4 = @truncate(u4, opcode);

        switch (opcode & 0xF000) {
            0x0000 => {
                if (opcode == 0x00E0)
                    return Opcode.cls;
                if (opcode == 0x00EE)
                    return Opcode.ret;
                return Opcode{ .sys = nnn };
            },
            0x1000 => return Opcode{ .jp = nnn },
            0x2000 => return Opcode{ .call = nnn },
            0x3000 => return Opcode{ .sexkk = .{ .x = x, .kk = kk } },
            0x4000 => return Opcode{ .snexkk = .{ .x = x, .kk = kk } },
            0x5000 => return Opcode{ .sexy = .{ .x = x, .y = y } },
            0x6000 => return Opcode{ .ldxkk = .{ .x = x, .kk = kk } },
            0x7000 => return Opcode{ .addxkk = .{ .x = x, .kk = kk } },
            0x8000 => {
                switch (n) {
                    0x0 => return Opcode{ .ldxy = .{ .x = x, .y = y } },
                    0x1 => return Opcode{ .orxy = .{ .x = x, .y = y } },
                    0x2 => return Opcode{ .andxy = .{ .x = x, .y = y } },
                    0x3 => return Opcode{ .xorxy = .{ .x = x, .y = y } },
                    0x4 => return Opcode{ .addxy = .{ .x = x, .y = y } },
                    0x5 => return Opcode{ .subxy = .{ .x = x, .y = y } },
                    0x6 => return Opcode{ .shrxy = .{ .x = x, .y = y } },
                    0x7 => return Opcode{ .subnxy = .{ .x = x, .y = y } },
                    0xE => return Opcode{ .shlxy = .{ .x = x, .y = y } },
                    else => return null,
                }
            },
            0x9000 => return Opcode{ .snexy = .{ .x = x, .y = y } },
            0xA000 => return Opcode{ .ldnnn = nnn },
            0xB000 => return Opcode{ .jpnnn = nnn },
            0xC000 => return Opcode{ .rndxkk = .{ .x = x, .kk = kk } },
            0xD000 => return Opcode{ .drwxyn = .{ .x = x, .y = y, .z = n } },
            0xE000 => {
                if (kk == 0x9E)
                    return Opcode{ .skpx = x };
                if (kk == 0xA1)
                    return Opcode{ .sknpx = x };
                return null;
            },
            0xF000 => {
                switch (kk) {
                    0x07 => return Opcode{ .ldxdt = x },
                    0x0A => return Opcode{ .ldxk = x },
                    0x15 => return Opcode{ .lddtx = x },
                    0x18 => return Opcode{ .ldstx = x },
                    0x1E => return Opcode{ .addix = x },
                    0x29 => return Opcode{ .ldfx = x },
                    0x33 => return Opcode{ .ldbx = x },
                    0x55 => return Opcode{ .ldix = x },
                    0x65 => return Opcode{ .ldxi = x },
                    else => return null,
                }
            },
            else => return null,
        }

        return null;
    }

    fn eq(self: Opcode, other: Opcode) bool {
        switch (self) {
            inline else => |val, tag| {
                if (tag != other)
                    return false;

                const oval = @field(other, @tagName(tag));

                if (@TypeOf(val) == void)
                    return true;
                if (@TypeOf(val) == Twelve)
                    return val == oval;
                if (@TypeOf(val) == Nibble)
                    return val == oval;
                if (@TypeOf(val) == DoubleNibble)
                    return val.x == oval.x and val.y == oval.y;
                if (@TypeOf(val) == TripleNibble)
                    return val.x == oval.x and val.y == oval.y and val.z == oval.z;
                if (@TypeOf(val) == NibbleByte)
                    return val.x == oval.x and val.kk == oval.kk;

                @compileError("Unhandled union variant");
            },
        }

        return false;
    }

    pub fn print(self: Opcode, pc: u16, writer: anytype) !void {
        switch (self) {
            .sys => |nnn| try writer.print("0x{X:0>4}: SYS 0x{X}\n", .{ pc, nnn }),
            .cls => try writer.print("0x{X:0>4}: CLS\n", .{pc}),
            .ret => try writer.print("0x{X:0>4}: RET\n", .{pc}),
            .jp => |nnn| try writer.print("0x{X:0>4}: JP 0x{X:0>4}\n", .{ pc, nnn }),
            .call => |nnn| try writer.print("0x{X:0>4}: CALL 0x{X:0>4}\n", .{ pc, nnn }),
            .sexkk => |nb| try writer.print("0x{X:0>4}: SE V{d}, 0x{X:0>2}\n", .{ pc, nb.x, nb.kk }),
            .snexkk => |nb| try writer.print("0x{X:0>4}: SNE V{d}, 0x{X:0>2}\n", .{ pc, nb.x, nb.kk }),
            .sexy => |dn| try writer.print("0x{X:0>4}: SE V{d}, V{d}\n", .{ pc, dn.x, dn.y }),
            .ldxkk => |nb| try writer.print("0x{X:0>4}: LD V{d}, 0x{X:0>2}\n", .{ pc, nb.x, nb.kk }),
            .addxkk => |nb| try writer.print("0x{X:0>4}: ADD V{d}, 0x{X:0>2}\n", .{ pc, nb.x, nb.kk }),
            .ldxy => |dn| try writer.print("0x{X:0>4}: LD V{d}, V{d}\n", .{ pc, dn.x, dn.y }),
            .orxy => |dn| try writer.print("0x{X:0>4}: OR V{d}, V{d}\n", .{ pc, dn.x, dn.y }),
            .andxy => |dn| try writer.print("0x{X:0>4}: AND V{d}, V{d}\n", .{ pc, dn.x, dn.y }),
            .xorxy => |dn| try writer.print("0x{X:0>4}: XOR V{d}, V{d}\n", .{ pc, dn.x, dn.y }),
            .addxy => |dn| try writer.print("0x{X:0>4}: ADD V{d}, V{d}\n", .{ pc, dn.x, dn.y }),
            .subxy => |dn| try writer.print("0x{X:0>4}: SUB V{d}, V{d}\n", .{ pc, dn.x, dn.y }),
            .shrxy => |dn| try writer.print("0x{X:0>4}: SHR V{d}\n", .{ pc, dn.x }),
            .subnxy => |dn| try writer.print("0x{X:0>4}: SUBN V{d}, V{d}\n", .{ pc, dn.x, dn.y }),
            .shlxy => |dn| try writer.print("0x{X:0>4}: SHL V{d}\n", .{ pc, dn.x }),
            .snexy => |dn| try writer.print("0x{X:0>4}: SNE V{d}, V{d}\n", .{ pc, dn.x, dn.y }),
            .ldnnn => |nnn| try writer.print("0x{X:0>4}: LD I, 0x{X:0>4}\n", .{ pc, nnn }),
            .jpnnn => |nnn| try writer.print("0x{X:0>4}: JP V0, 0x{X:0>4}\n", .{ pc, nnn }),
            .rndxkk => |nb| try writer.print("0x{X:0>4}: RND V{d}, 0x{X:0>2}\n", .{ pc, nb.x, nb.kk }),
            .drwxyn => |tn| try writer.print("0x{X:0>4}: DRW V{d}, V{d}, 0x{X}\n", .{ pc, tn.x, tn.y, tn.z }),
            .skpx => |x| try writer.print("0x{X:0>4}: SKP V{d}\n", .{ pc, x }),
            .sknpx => |x| try writer.print("0x{X:0>4}: SKNP V{d}\n", .{ pc, x }),
            .ldxdt => |x| try writer.print("0x{X:0>4}: LD V{d}, DT\n", .{ pc, x }),
            .ldxk => |x| try writer.print("0x{X:0>4}: LD V{d}, K\n", .{ pc, x }),
            .lddtx => |x| try writer.print("0x{X:0>4}: LD DT, V{d}\n", .{ pc, x }),
            .ldstx => |x| try writer.print("0x{X:0>4}: LD ST, V{d}\n", .{ pc, x }),
            .addix => |x| try writer.print("0x{X:0>4}: ADD I, V{d}\n", .{ pc, x }),
            .ldfx => |x| try writer.print("0x{X:0>4}: LD F, V{d}\n", .{ pc, x }),
            .ldbx => |x| try writer.print("0x{X:0>4}: LD B, V{d}\n", .{ pc, x }),
            .ldix => |x| try writer.print("0x{X:0>4}: LD [I], V{d}\n", .{ pc, x }),
            .ldxi => |x| try writer.print("0x{X:0>4}: LD V{d}, [I]\n", .{ pc, x }),
        }
    }
};

test "opcode decode" {
    const expect = @import("std").testing.expect;

    const Case = struct {
        opcode: u16,
        expected: Opcode,
    };

    // TODO(alexandre): add more test cases.
    const cases = [_]Case{
        Case{ .opcode = 0xA2B4, .expected = Opcode{ .ldnnn = 0x2B4 } },
        Case{ .opcode = 0x23E6, .expected = Opcode{ .call = 0x3E6 } },
    };

    for (cases) |case| {
        const got = Opcode.decode(case.opcode) orelse return Error.IllegalOpcode;
        try expect(got.eq(case.expected));
    }
}
