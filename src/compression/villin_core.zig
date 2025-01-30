const std = @import("std");

pub const VillnError = error{
    StreamError,
    OutOfMemory,
    StreamAlreadyInitialized,
    StreamNotInitialized,
};

pub const CompressEngine = struct {
    pub const MetricsData = struct {
        bytes_in: usize = 0,
        bytes_out: usize = 0,
        patterns_found: usize = 0,
    };

    allocator: std.mem.Allocator,
    config: CompressConfig,
    metrics: ?*MetricsData,
    stream: ?*StreamHandler,
    wrapper_ctx: ?*WrapperContext = null,

    pub const CompressConfig = struct {
        pattern_threshold: f64 = 0.95,
        min_pattern_length: usize = 4,
        max_pattern_length: usize = 1024,
        window_size: usize = 4096,
        stream_buffer_size: usize = 8192,
    };

    pub const StreamContext = struct {
        received: std.ArrayList(u8),
        allocator: std.mem.Allocator,

        pub fn init(alloc: std.mem.Allocator) !@This() {
            return .{
                .received = std.ArrayList(u8).init(alloc),
                .allocator = alloc,
            };
        }

        pub fn deinit(self: *@This()) void {
            self.received.deinit();
        }
    };

    const WrapperContext = struct {
        ctx: *StreamContext,
        cb: *const fn(*StreamContext, []const u8) VillnError!void,

        pub fn init(ctx: *StreamContext, callback: *const fn(*StreamContext, []const u8) VillnError!void) @This() {
            return .{
                .ctx = ctx,
                .cb = callback,
            };
        }

        pub fn wrap(self: *const @This(), data: []const u8) VillnError!void {
            try self.cb(self.ctx, data);
        }
    };

    pub const StreamHandler = struct {
        buffer: []u8,
        write_pos: usize,
        callback: *const fn([]const u8) VillnError!void,

        pub fn init(allocator: std.mem.Allocator, size: usize, cb: *const fn([]const u8) VillnError!void) !*StreamHandler {
            const handler = try allocator.create(StreamHandler);
            errdefer allocator.destroy(handler);
            
            const buf = try allocator.alloc(u8, size);
            errdefer allocator.free(buf);

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
            .wrapper_ctx = null,
        };
        return engine;
    }

    pub fn initStreaming(self: *CompressEngine, ctx: *StreamContext, callback: *const fn(*StreamContext, []const u8) VillnError!void) !void {
        if (self.stream != null) return error.StreamAlreadyInitialized;
    
        const wrapper_ctx = try self.allocator.create(WrapperContext);
        wrapper_ctx.* = WrapperContext.init(ctx, callback);
    
        self.wrapper_ctx = wrapper_ctx;
        
        const StreamCallback = struct {
            wrapper_ctx: *const WrapperContext,
    
            pub fn handleData(cb: *const @This(), data: []const u8) VillnError!void {
                try cb.wrapper_ctx.wrap(data);
            }
        };
    
        const stream_callback = try self.allocator.create(StreamCallback);
        stream_callback.* = StreamCallback{ .wrapper_ctx = wrapper_ctx };
    
        // ✅ Use a standalone wrapper function
        fn callbackWrapper(data: []const u8) VillnError!void {
            try stream_callback.handleData(stream_callback, data),
        }
    
        self.stream = try StreamHandler.init(
            self.allocator,
            self.config.stream_buffer_size,
            callbackWrapper, // ✅ Fixed: Correct function signature
        );
    };

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

    fn findPattern(self: *CompressEngine, data: []const u8) !?Pattern {
        if (data.len < self.config.min_pattern_length) return null;

        const max_len = @min(data.len, self.config.max_pattern_length);
        var best_pattern: ?Pattern = null;
        var best_savings: isize = 0;

        var len: usize = self.config.min_pattern_length;
        while (len <= max_len) : (len += 1) {
            const pattern = data[0..len];
            var repeats: usize = 0;
            var pos: usize = len;

            while (pos + len <= data.len and std.mem.eql(u8, pattern, data[pos..pos+len])) {
                repeats += 1;
                pos += len;
            }

            if (repeats > 0) {
                const encoded_size = 2 + len;
                const raw_size = len * repeats;
                const savings = @as(isize, @intCast(raw_size)) - @as(isize, @intCast(encoded_size));

                if (savings > best_savings) {
                    best_pattern = Pattern{
                        .start = 0,
                        .len = len,
                        .repeats = repeats,
                    };
                    best_savings = savings;
                }
            }
        }
        return best_pattern;
    }

    fn encodePattern(_: *CompressEngine, result: *std.ArrayList(u8), pattern: Pattern) !void {
        try result.append(0xFF);
        try result.append(@as(u8, @intCast(pattern.len)));
        try result.append(@as(u8, @intCast(pattern.repeats)));
    }

    pub fn deinit(self: *CompressEngine) void {
        if (self.stream) |stream| {
            stream.deinit(self.allocator);
        }
        if (self.wrapper_ctx) |wrapper_ctx| {
            self.allocator.destroy(wrapper_ctx);
        }
        self.allocator.destroy(self);
    }
};

test "Streaming compression" {
    const allocator = std.testing.allocator;
    var context = try CompressEngine.StreamContext.init(allocator);
    defer context.deinit();

    var engine = try CompressEngine.init(allocator, .{});
    defer engine.deinit();

    const callback = struct {
        fn cb(stream_ctx: *CompressEngine.StreamContext, data: []const u8) VillnError!void {
            try stream_ctx.received.appendSlice(data);
        }
    }.cb;

    try engine.initStreaming(&context, callback);

    const test_data = "ABCABCABCABC";
    try engine.writeStream(test_data);
    try engine.stream.?.flush();

    try std.testing.expect(context.received.items.len < test_data.len);
}

test "Compression patterns" {
    const allocator = std.testing.allocator;
    var engine = try CompressEngine.init(allocator, .{});
    defer engine.deinit();

    const test_data = "ABCABCABCABC";
    const compressed = try engine.compress(test_data);
    defer allocator.free(compressed);

    try std.testing.expect(compressed.len < test_data.len);
}

test "Memory cleanup" {
    const allocator = std.testing.allocator;
    var engine = try CompressEngine.init(allocator, .{});
    defer engine.deinit();

    var context = try CompressEngine.StreamContext.init(allocator);
    defer context.deinit();

    const callback = struct {
        fn cb(stream_ctx: *CompressEngine.StreamContext, data: []const u8) VillnError!void {
            try stream_ctx.received.appendSlice(data);
        }
    }.cb;

    try engine.initStreaming(&context, callback);
}