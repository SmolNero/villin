const std = @import("std");

pub fn build(b: *std.Build) void {

    // Standard target options allows the person running 'zig build' to choose
    // what target to build for. Here we do not override the defaults

    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running 'zig build' to select
    // between Debug, ReleaseSafe, releaseFast, and ReleaseSmall

    const optimize = b.standardOptimizeOptions(.{});

    const exe = b.addExecutable(.{
        .name = "villin",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" steps

    b.installArtifact(exe);

    // Creates a step for unit testing

    const unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .taget = target,
        .optimize = optimize,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);

    // This creates a build step. It will be visible in the 'zig --help' menu
    // and can be selected like this: 'zig build test'
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
