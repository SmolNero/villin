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
pub fn build(b: *std.Build) void {

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
