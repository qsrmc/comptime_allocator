const std = @import("std");

const VTable = std.mem.Allocator.VTable;
const Allocator = std.mem.Allocator;

const vtable = VTable{
    .alloc = alloc,
    .resize = resize,
    .free = free,
    .remap = remap,
};

pub const allocator = Allocator{
    .vtable = &vtable,

    // There is no such thing as state for that allocator
    .ptr = undefined,
};

fn alloc(_: *anyopaque, len: usize, ptr_align: std.mem.Alignment, ret_addr: usize) ?[*]u8 {
    if (!@inComptime())
        @panic("Comptime allocator has to be called in comptime");

    if (ret_addr != 0)
        @compileError("ret_addr cannot be non-zero");

    var array align(1 << ptr_align.toByteUnits()) = [_]u8{undefined} ** len;
    return &array;
}

fn resize(_: *anyopaque, buf: []u8, ptr_align: std.mem.Alignment, new_len: usize, ret_addr: usize) bool {
    _ = ptr_align;

    if (!@inComptime())
        @panic("Comptime allocator has to be called in comptime");

    if (ret_addr != 0)
        @compileError("ret_addr cannot be non-zero");

    // We can't resize up within a comptime context
    if (new_len <= buf.len) {
        const diff = buf.len - new_len;
        if (diff != 0) {
            @setRuntimeSafety(false);
            @memset(buf[buf.len - diff ..], undefined);
        }
        return true;
    }
    return false;
}

fn free(_: *anyopaque, buf: []u8, ptr_align: std.mem.Alignment, ret_addr: usize) void {
    _ = ptr_align;

    if (!@inComptime())
        @panic("Comptime allocator has to be called in comptime");

    if (ret_addr != 0)
        @compileError("ret_addr cannot be non-zero");

    // Just set everything to undefined to avoid use after frees
    @memset(buf, undefined);
}

fn remap(_: *anyopaque, buf: []u8, ptr_align: std.mem.Alignment, new_len: usize, ret_addr: usize) ?[*]u8 {
    if (!@inComptime())
        @panic("Comptime allocator has to be called in comptime");

    if (ret_addr != 0)
        @compileError("ret_addr cannot be non-zero");

    var new_mem: [new_len]u8 align(1 << ptr_align.toByteUnits()) = undefined;
    const to_copy = @min(new_len, buf.len);
    {
        // Not sure this would work at comptime, but just in case
        @setRuntimeSafety(false);
        @memcpy(new_mem[0..to_copy], buf);
    }
    return &new_mem;
}

test "resize down" {
    const worked = comptime blk: {
        const h = try allocator.alloc(u8, 10);
        break :blk allocator.resize(h, 5);
    };

    try std.testing.expect(worked);
}

test "resize up" {
    const worked = comptime blk: {
        const h = try allocator.alloc(u8, 10);
        break :blk allocator.resize(h, 15);
    };

    try std.testing.expect(!worked);
}

test "realloc a bit" {
    comptime {
        // As of writing this code you need around 30000 backwards branch
        @setEvalBranchQuota(30000);

        var h = try allocator.alloc(u8, 10);
        for (0..1000) |i| {
            h = try allocator.realloc(h, i);
        }
        allocator.free(h);
    }

    try std.testing.expect(true);
}

test "create" {
    comptime var a: *i32 = undefined;
    comptime {
        a = try allocator.create(i32);
        a.* = 42;
    }
    try std.testing.expect(a.* == 42);
}

test "comptime ArrayList" {
    const hello_world = comptime blk: {
        var array_list = std.ArrayList(u8).init(allocator);

        try array_list.appendSlice("Helloo");
        try array_list.appendSlice("wworld!");

        try array_list.replaceRange(5, 2, ", ");

        // You cannot use a pointer allocated at compile time during runtime,
        // but you can copy its content to a static array
        var out_buf: [array_list.items.len]u8 = undefined;
        @memcpy(&out_buf, array_list.items);
        break :blk out_buf;
    };
    try std.testing.expectEqualSlices(u8, "Hello, world!", &hello_world);
}

test "comptime json" {
    const Struct = struct {
        id: u32,
        name: []const u8,
        the: []const u8,
    };
    const value: Struct = comptime blk: {
        const slice =
            \\{
            \\  "id": 42,
            \\  "name": "bnl1",
            \\  "the": "game"
            \\}
        ;

        const value = std.json.parseFromSliceLeaky(
            Struct,
            allocator,
            slice,
            .{},
        ) catch |err| @compileError(std.fmt.comptimePrint(
            "json parsing error {s}\n",
            .{@errorName(err)},
        ));
        break :blk value;
    };

    try std.testing.expectEqualDeep(
        Struct{
            .id = 42,
            .name = "bnl1",
            .the = "game",
        },
        value,
    );
}
