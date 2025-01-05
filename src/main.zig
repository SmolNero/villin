// main.zig objectives
//  ---------------- //
//    - Entry point for all funtionality 
//    - Core compression logic
//    - Pattern detection
//    - Data handeling
//    - API endpoints
//    - Testing blocks

const std = @import("std");

// This is Villins entry point
// the '!' indicates this function can return an error
// void means it doesn'treturn value
pub fn main() !void {
    std.debug.print("Villin: Starting up...\n", .{});
}

// TEST BLOCK 1
test "basic" {
    std.debug.print("\nRunning basic...\n", .{});
    try std.testing.expect(true);
    std.debug.print("Basic test passed\n", .{});
}

// TEST BLOCK 2
test "compression placeholder" {
    std.debug.print("\nTesting compression placeholder...\n", .{});
    const result = true;
    try std.testing.expectEqual(true, result);
    std.debug.print("compression test passed!", .{});
}

// test
// └─ run test stderr  -> Shows test execution
// Running basic...    -> First test starts
// Basic test passed   -> First test ends

// Testing compression placeholder...   -> Second test starts
// compression test passed!             -> second test ends
