// src/compression/tests/villn_core_test.zig
const std = @import("std");
const villn = @import("../villin_core.zig");

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

test "Compression patterns" {
    const allocator = testing.allocator;
    
    // Initialize engine
    var engine = try CompressEngine.init(allocator, .{});
    defer engine.deinit();

    // Test compression
    const test_data = "ABCABCABCABC";
    const compressed = try engine.compress(test_data);
    defer allocator.free(compressed);

    // Verify compression
    try testing.expect(compressed.len < test_data.len);
}

test "Memory cleanup" {
    const allocator = testing.allocator;
    
    // Initialize engine
    var engine = try CompressEngine.init(allocator, .{});
    defer engine.deinit();

    // Initialize context
    var context = try CompressEngine.StreamContext.init(allocator);
    defer context.deinit();

    // Setup and test callback
    const callback = struct {
        fn cb(stream_ctx: *CompressEngine.StreamContext, data: []const u8) villn.VillnError!void {
            try stream_ctx.received.appendSlice(data);
        }
    }.cb;

    try engine.initStreaming(&context, callback);
}

// Additional test cases for specific compression scenarios
test "Compression with repeated patterns" {
    const allocator = testing.allocator;
    var engine = try CompressEngine.init(allocator, .{});
    defer engine.deinit();

    const test_data = "ABCABCABCABC";
    const compressed = try engine.compress(test_data);
    defer allocator.free(compressed);

    try testing.expect(compressed.len < test_data.len);
    
    // Test pattern detection
    if (try engine.findPattern(test_data[0..])) |pattern| {
        try testing.expectEqual(@as(usize, 3), pattern.len);
        try testing.expectEqual(@as(usize, 3), pattern.repeats);
    } else {
        try testing.expect(false); // Pattern should be found
    }
}