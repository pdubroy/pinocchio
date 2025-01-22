const std = @import("std");

const Registers = struct {
    a: u8,
    b: u8,
    c: u8,
    d: u8,
    e: u8,
    f: u8,
    h: u8,
    l: u8,

    pub fn getBC(self: *const Registers) u16 {
        return (@as(u16, self.b) << 8) | self.c;
    }

    pub fn setBC(self: *Registers, value: u16) void {
        self.b = @truncate((value >> 8) & 0xFF);
        self.c = @truncate(value & 0xFF);
    }

    pub fn getAF(self: *const Registers) u16 {
        return (@as(u16, self.a) << 8) | self.f;
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

test "registers" {
    var regs = Registers{
        .a = 0x12,
        .b = 0x34,
        .c = 0x56,
        .d = 0x78,
        .e = 0x9A,
        .f = 0xBC,
        .h = 0xDE,
        .l = 0xF0,
    };
    try std.testing.expectEqual(regs.getBC(), 0x3456);
    try std.testing.expectEqual(regs.getDE(), 0x789A);
    try std.testing.expectEqual(regs.getAF(), 0x12BC);

    regs.a = 1;
    try std.testing.expectEqual(regs.a, 1);
    regs.l = 99;
    try std.testing.expectEqual(regs.l, 99);
}
