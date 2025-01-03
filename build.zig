const std = @import("std");


pub fn build(b: *std.Build) void {

    // Standard optimization options allow the person running 'zig build' to select
    // between Debug, ReleaseSafe, releaseFast, and ReleaseSmall
    const optimize = b.standarOptimizationOption(.{});
    
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
        .root_source_file = .{.path = "src/main.zig"},
        .taget = target,
        .optimize = optimize
    });

}