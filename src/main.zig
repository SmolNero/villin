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
// test out goes to stderr
// Prints a success message if we made it this far (meaning the expect did not fail)
test "basic" {
    std.debug.print("\nRunning basic...\n", .{});
    try std.testing.expect(true);  // checks if given conditions are true - if not -> test fails (returns error)
    std.debug.print("Basic test passed\n", .{});
}

// TEST BLOCK 2
// This is a placeholder for real compression tests
test "compression placeholder" {
    std.debug.print("\nTesting compression placeholder...\n", .{});
    const result = true;       // Declares a compile-time constant, set to true
    try std.testing.expectEqual(true, result);  // compares values
    std.debug.print("compression test passed!", .{});
}

// test
// └─ run test stderr  -> Shows test execution
// Running basic...    -> First test starts
// Basic test passed   -> First test ends

// Testing compression placeholder...   -> Second test starts
// compression test passed!             -> second test ends
