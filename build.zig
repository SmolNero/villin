// build.zig objectives
//  ---------------- //
//  - Build configuration
//  - Dependacy management
//  - Compilation settings
//  - Build targets
//  - Test setup
//  - Web dashboards integration

const std = @import("std");

pub fn build(b: *std.Build) void {

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "villin",
        .root_source_file = .{ .cwd_relative = "src/main.zig" }, // .cwd_relative -> takes relative path
        .target = target, // ensuring the executable is built for the selected achitects/OS/ABI
        .optimize = optimize, // pass the optimization level determined earlier
    });

    b.installArtifact(exe);
    const unit_tests = b.addTest(.{
        .root_source_file = .{ .cwd_relative = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
