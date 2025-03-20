# comptime_allocator

Based on [bnl1's work](https://github.com/bnl1/comptime_allocator) and expanded
upon, this library was made to simplify the use of std lib containers in
comptime contexts.

## License

While [bnl1's original work](https://github.com/bnl1/comptime_allocator) was
made under MIT License, comptime_allocator is licensed under the
[European Union Public License 1.2](https://joinup.ec.europa.eu/collection/eupl/eupl-text-eupl-12)
or later.

## Example

Directly from the tests:
```zig
const allocator = @import("comptime_allocator");

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
```

## FAQ

### Why use that allocator?

It makes using containers from the standard library really easy, therefore
making most dynamic function calls callable in a comptime context.

### Why is this library under a copyleft license?

I hate proprietary software, just thinking that my code could be used in some
makes me puke.

### But I can't use it for my own projects >:(

Get over it.
Use a copyleft license.
Make the world a better place.
