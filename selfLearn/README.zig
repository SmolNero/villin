
			________________________________________________________________________________
			
											{build.zig}
			________________________________________________________________________________
			

// build.zig objectives
//  ---------------- //
//  - Build configuration
//  - Dependacy management
//  - Compilation settings
//  - Build targets
//  - Test setup
//  - Web dashboards integration

const std = @import("std");

// Build function is the entry point to Zig builds system
// It receives a pointer to the Build object which provides build functionality
pub fn build(b: *b.Build) void {

    // Standard target options allows the person running 'zig build' to choose
    
    // standardTargetOptions - helper method from std.build that initlializes and processes target architecture, OS, and ABI options based on command-line flags
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running 'zig build' to select
    // standardOptimieOption stand lib helper that picks the optimize level
    // opt levels - between Debug, ReleaseSafe, releaseFast, and ReleaseSmall
    const optimize = b.standardOptimizeOption(.{});

    // Allows cross-compilation for diff insustrial
    // b(std.Build pointer) -> creates new executable build artifact
    // Can target PLCs, embedded devices, or servers
    const exe = b.addExecutable(.{
        .name = "villin",
        .root_source_file = .{ .cwd_relative = "src/main.zig" }, // .cwd_relative -> takes relative path
        .target = target, // ensuring the executable is built for the selected achitects/OS/ABI
        .optimize = optimize, // pass the optimization level determined earlier
    });

    b.installArtifact(exe);
    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" steps
    // without this, the build system would not know where you want to install the binary
    // exe -> is the build artifact you previously created

    // creates a test build artifact, when built/run, (exe)cutes tge unit test src/main.zig
    // *.addTest -> test build artifact
    const unit_tests = b.addTest(.{
        .root_source_file = .{ .cwd_relative = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    //Convenience method that creates a step to build and run the given artifact -> (unit_tests)
    const run_unit_tests = b.addRunArtifact(unit_tests);

    // This creates a build step. It will be visible in the 'zig --help' menu
    // and can be selected like this: 'zig build test'
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
		
		________________________________________________________________________________

									{src/main.zig}
		________________________________________________________________________________

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


		________________________________________________________________________________

									{src/compression/villin_core.zig}
		________________________________________________________________________________


/// villin_core.zig objectives
//	- Pattern detection
//	- Compression logic  
//	- Memory management
//	- unit test
//	- streaming suppor: This enables VILLIN to process continuous data streams with minimal
//	  memory overhead
//		* StreamHandler struct: Managers buffered data processing
//		* Streaming method
//		* configuration




cont std = @import("std");




	// ?* -> ? = optional pointer * = denotes that this is a pointer type 
pub const CompresEngine = struct {
	allocator: std.mem. Allocator,

}


// How does our StreamHandler work?
// consider the buffer -> temporary storage 
//		|_
//		   This is heavily utilized when working with streams, reading and writing smaller pieces - for 	
//		   effecincy
//		|_				
//			Leveraging an unsigned 8-bit int NO NO NEGATIVES!)
//
//


pub const StreamHandler = struct {
	buffer: []u8,
	write_pos: usize,
	callback: *const fn([]const u8) error{SteamError}!void,
}
