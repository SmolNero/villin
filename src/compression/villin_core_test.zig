// src/compression/villin_core_test.zig
const std = @import("std");
const villn = @import("villin_core.zig");  // Direct import since in same directory

const testing = std.testing;
const CompressEngine = villn.CompressEngine;

test "Streaming compression" {
    const allocator = testing.allocator;
    
    // Initialize context
    var context = try CompressEngine.StreamContext.init(allocator);
    defer context.deinit();

    // Initialize engine
    var engine = try CompressEngine.init(allocator, .{});
    defer engine.deinit();

    // Setup callback
    const callback = struct {
        fn cb(stream_ctx: *CompressEngine.StreamContext, data: []const u8) villn.VillnError!void {
            try stream_ctx.received.appendSlice(data);
        }
    }.cb;

    // Test streaming
    try engine.initStreaming(&context, callback);
    const test_data = "ABCABCABCABC";
    try engine.writeStream(test_data);
    try engine.stream.?.flush();

    // Verify compression
    try testing.expect(context.received.items.len < test_data.len);
}

// [Other test cases remain the same...]