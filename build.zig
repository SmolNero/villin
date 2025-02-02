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

    // Tests
    const tests = b.addTest(.{
        .root_source_file = .{ .path = "src/compression/villin_core_test.zig" },
        .target = target,
        .optimize = optimize,
    });

    const test_step = b.step("test", "Run all tests");
    const run_tests = b.addRunArtifact(tests);
    test_step.dependOn(&run_tests.step);
}