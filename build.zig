// build.zig objectives
//  ---------------- //
//  - Build configuration
//  - Dependency management
//  - Compilation settings
//  - Build targets
//  - Test setup
//  - Web dashboard integration

const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Main executable
    const exe = b.addExecutable(.{
        .name = "villin",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(exe);

    // Run command
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    const run_step = b.step("run", "Run villin");
    run_step.dependOn(&run_cmd.step);

    // Unit tests
    const core_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/compression/test/villin_core_test.zig" },
        .target = target,
        .optimize = optimize,
    });

    // Main tests
    const main_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    // Combined test step
    const test_step = b.step("test", "Run all tests");
    const run_core_tests = b.addRunArtifact(core_tests);
    const run_main_tests = b.addRunArtifact(main_tests);
    test_step.dependOn(&run_core_tests.step);
    test_step.dependOn(&run_main_tests.step);
}