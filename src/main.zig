const std = @import("std");

pub fn main() !void {
    std.debug.print("VILLIN: Startings up...\n", .{});
}

test "basic" {
    try std.testing.expect(true);
}
