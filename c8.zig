const std = @import("std");

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
    unknown: void,

    pub fn decode(opcode: u16) Opcode {
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
                    else => return Opcode.unknown,
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
                return Opcode.unknown;
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
                    else => return Opcode.unknown,
                }
            },
            else => return Opcode.unknown,
        }

        return Opcode.unknown;
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

                @compileError("Unknown union type");
            },
        }

        return false;
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
        const got = Opcode.decode(case.opcode);
        try expect(got.eq(case.expected));
    }
}
