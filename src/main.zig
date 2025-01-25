// main.zig objectives
//  ---------------- //
//    - Entry point for all funtionality 
//    - Core compression logic
//    - Pattern detection
//    - Data handeling
//    - API endpoints
//    - Testing blocks

const std = @import("std");

pub fn main() !void {
    std.debug.print("Villin: Starting up...\n", .{});
}

test "basic" {
    std.debug.print("\nRunning basic...\n", .{});
    try std.testing.expect(true);  // checks if given conditions are true - if not -> test fails (returns error)
    std.debug.print("Basic test passed\n", .{});
}

test "compression placeholder" {
    std.debug.print("\nTesting compression placeholder...\n", .{});
    const result = true;       // Declares a compile-time constant, set to true
    try std.testing.expectEqual(true, result);  // compares values
    std.debug.print("compression test passed!", .{});
}
