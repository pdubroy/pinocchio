const std = @import("std");

const Registers = struct {
    a: u8 = 0,
    b: u8 = 0,
    c: u8 = 0,
    d: u8 = 0,
    e: u8 = 0,
    f: packed union {
        raw: u8,
        flags: Flags,
    } = .{ .raw = 0 },
    h: u8 = 0,
    l: u8 = 0,

    pub fn getBC(self: *const Registers) u16 {
        return (@as(u16, self.b) << 8) | self.c;
    }

    pub fn setBC(self: *Registers, value: u16) void {
        self.b = @truncate((value >> 8) & 0xFF);
        self.c = @truncate(value & 0xFF);
    }

    pub fn getAF(self: *const Registers) u16 {
        return (@as(u16, self.a) << 8) | self.f.raw;
    }

    pub fn setAF(self: *Registers, value: u16) void {
        self.a = @truncate((value >> 8) & 0xFF);
        self.f = @truncate(value & 0xFF);
    }

    pub fn getDE(self: *const Registers) u16 {
        return (@as(u16, self.d) << 8) | self.e;
    }

    pub fn setDE(self: *Registers, value: u16) void {
        self.d = @truncate((value >> 8) & 0xFF);
        self.e = @truncate(value & 0xFF);
    }

    pub fn getHL(self: *const Registers) u16 {
        return (@as(u16, self.h) << 8) | self.l;
    }

    pub fn setHL(self: *Registers, value: u16) void {
        self.h = @truncate((value >> 8) & 0xFF);
        self.l = @truncate(value & 0xFF);
    }
};

//
// https://zig.news/edyu/zig-unionenum-wtf-is-switchunionenum-2e02
const ZERO_FLAG_BYTE_POSITION: u8 = 7;
const SUBTRACT_FLAG_BYTE_POSITION: u8 = 6;
const HALF_CARRY_FLAG_BYTE_POSITION: u8 = 5;
const CARRY_FLAG_SHIFT: u8 = 4;

const Flags = packed struct {
    _: u4 = 0,
    carry: u1 = false,
    halfCarry: u1 = false,
    subtract: u1 = false,
    zero: u1 = false,
};

const ArithmeticTarget = enum {
    A,
    B,
    C,
    D,
    E,
    H,
    L,
};

const Instruction = union(enum) {
    ADD: ArithmeticTarget,
};

const CPU = struct {
    reg: Registers = .{},

    pub fn execute(self: *CPU, instruction: Instruction) void {
        switch (instruction) {
            Instruction.ADD => |target| {
                switch (target) {
                    ArithmeticTarget.C => {
                        const old = self.reg.a;
                        const operand = self.reg.c;
                        const result = @addWithOverflow(old, operand);
                        self.reg.a = result[0];
                        self.reg.f.flags.zero = @intCast(@intFromBool(result[0] == 0));
                        self.reg.f.flags.carry = result[1];
                        self.reg.f.flags.halfCarry = @intCast(@intFromBool(((old & 0xF) + (operand & 0xF)) > 0xF));
                        self.reg.f.flags.subtract = 0;
                    },
                    else => {
                        std.debug.print("All your {s} are belong to us.\n", .{"codebase"});
                    },
                }
            },
        }
    }

    pub inline fn zero(self: *const CPU) bool {
        return self.reg.f.flags.zero == 1;
    }
    pub inline fn carry(self: *const CPU) bool {
        return self.reg.f.flags.carry == 1;
    }
    pub inline fn halfCarry(self: *const CPU) bool {
        return self.reg.f.flags.halfCarry == 1;
    }
    pub inline fn subtract(self: *const CPU) bool {
        return self.reg.f.flags.subtract == 1;
    }
};

pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("Run `zig build test` to run the tests.\n", .{});

    try bw.flush(); // don't forget to flush!
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

test "8-bit registers" {
    var regs = Registers{};
    regs.a = 1;
    try std.testing.expectEqual(regs.a, 1);
    regs.l = 99;
    try std.testing.expectEqual(regs.l, 99);
}

test "16-bit registers" {
    var regs = Registers{
        .a = 0x12,
        .b = 0x34,
        .c = 0x56,
        .d = 0x78,
        .e = 0x9A,
        .f = .{ .raw = 0xBC },
        .h = 0xDE,
        .l = 0xF0,
    };
    try std.testing.expectEqual(regs.getBC(), 0x3456);
    try std.testing.expectEqual(regs.getDE(), 0x789A);
    try std.testing.expectEqual(regs.getAF(), 0x12BC);

    regs.setHL(0x1234);
    try std.testing.expectEqual(regs.h, 0x12);
    try std.testing.expectEqual(regs.l, 0x34);
    try std.testing.expectEqual(regs.getHL(), 0x1234);
}

test "add instruction" {
    var cpu = CPU{};
    cpu.reg.a = 250;
    cpu.reg.c = 10;
    const inst = Instruction{ .ADD = .C };

    cpu.execute(inst);

    try std.testing.expectEqual(cpu.reg.a, 4);
    try std.testing.expectEqual(cpu.carry(), true);

    // Non-overflowing add too
    cpu = CPU{};
    cpu.reg.a = 5;
    cpu.reg.c = 3;
    cpu.execute(inst);

    try std.testing.expectEqual(cpu.reg.a, 8);
    try std.testing.expectEqual(cpu.carry(), false);
}
