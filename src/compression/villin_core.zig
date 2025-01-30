const std = @import("std");

// Core Engine components
pub const CompressEngine = struct {
    pub const MetricsData = struct {
        bytes_in: usize = 0,
        bytes_out: usize = 0,
        patterns_found: usize = 0,
    };

    allocator: std.mem.Allocator,
    config: CompressConfig,
    metrics: ?*MetricsData,
    stream: ?*StreamHandler, // Streaming support

    pub const CompressConfig = struct {
        pattern_threshold: f64 = 0.95,
        min_pattern_length: usize = 4,
        max_pattern_length: usize = 1024,
        window_size: usize = 4096,
        stream_buffer_size: usize = 8192, // Stream buffer configuration
    };

    pub const StreamHandler = struct {
        buffer: []u8, 
        write_pos: usize, 
        callback: *const fn([]const u8) error{StreamError}!void, 

        pub fn init(allocator: std.mem.Allocator, size: usize, cb: *const fn([]const u8) error{StreamError}!void) !*StreamHandler {
            const handler = try allocator.create(StreamHandler);
            const buf = try allocator.alloc(u8, size);

            handler.* = .{
                .buffer = buf,
                .write_pos = 0,
                .callback = cb,
            };
            return handler;
        }

        pub fn write(self: *StreamHandler, data: []const u8) !void {
            if (self.write_pos + data.len > self.buffer.len) {
                try self.flush(); 
            }

            @memcpy(self.buffer[self.write_pos..][0..data.len], data);
            self.write_pos += data.len;
        }

        pub fn flush(self: *StreamHandler) !void {
            if (self.write_pos == 0) return;
            try self.callback(self.buffer[0..self.write_pos]);
            self.write_pos = 0;
        }

        pub fn deinit(self: *StreamHandler, allocator: std.mem.Allocator) void {
            allocator.free(self.buffer);
            allocator.destroy(self);
        }
    };

    pub fn init(allocator: std.mem.Allocator, config: CompressConfig) !*CompressEngine {
        const engine = try allocator.create(CompressEngine);
        engine.* = .{
            .allocator = allocator,
            .config = config,
            .metrics = null,
            .stream = null,
        };
        return engine;
    }

    // Streaming initialization with wrapper function
    pub fn initStreaming(self: *CompressEngine, ctx: *TestContext, callback: *const fn (*TestContext, []const u8) error{StreamError}!void) !void {
        if (self.stream != null) return error.StreamAlreadyInitialized;

        fn wrapper(data: []const u8) error{StreamError}!void {
            try callback(ctx, data),
        };

        self.stream = try StreamHandler.init(self.allocator, self.config.stream_buffer_size, wrapper);
    }

    pub fn writeStream(self: *CompressEngine, data: []const u8) !void {
        if (self.stream == null) return error.StreamNotInitialized;

        const compressed = try self.compress(data);
        defer self.allocator.free(compressed);

        try self.stream.?.write(compressed);
    }

    pub fn compress(self: *CompressEngine, data: []const u8) ![]u8 {
        var result = std.ArrayList(u8).init(self.allocator);
        errdefer result.deinit();

        var i: usize = 0;
        while (i < data.len) {
            if (try self.findPattern(data[i..])) |pattern| {
                try self.encodePattern(&result, pattern);
                i += pattern.len;
            } else {
                try result.append(data[i]);
                i += 1;
            }
        }

        return result.toOwnedSlice();
    }

    const Pattern = struct {
        start: usize,
        len: usize,
        repeats: usize,
    };

    fn encodePattern(_: *CompressEngine, result: *std.ArrayList(u8), pattern: Pattern) !void {
        try result.append(0xFF);
        try result.append(@intCast(u8, pattern.len));
        try result.append(@intCast(u8, pattern.repeats));
    }

    pub fn deinit(self: *CompressEngine) void {
        if (self.stream) |stream| {
            stream.deinit(self.allocator);
        }
        self.allocator.destroy(self);
    }
};

// Test streaming functionality
test "Streaming compression" {
    const TestContext = struct {
        received: std.ArrayList(u8),
        allocator: std.mem.Allocator,

        pub fn init(alloc: std.mem.Allocator) !@This() {
            return .{
                .received = std.ArrayList(u8).init(alloc),
                .allocator = alloc,
            };
        }
    };

    const allocator = std.testing.allocator;
    var ctx = try TestContext.init(allocator);
    defer ctx.received.deinit();

    var engine = try CompressEngine.init(allocator, .{});
    defer engine.deinit();

    fn callback(ctx: *TestContext, data: []const u8) error{StreamError}!void {
        ctx.received.appendSlice(data) catch |err| switch (err) {
            error.OutOfMemory => return error.StreamError,
            else => return err, // Forward unexpected errors
        };
    } // ✅ Added missing semicolon

    try engine.initStreaming(&ctx, callback);

    const test_data = "ABCABCABCABC";
    try engine.writeStream(test_data);
    try engine.stream.?.flush();

    try std.testing.expect(ctx.received.items.len < test_data.len);
}