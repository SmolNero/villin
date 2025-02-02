// src/compression/villin_core.zig
const std = @import("std");

pub const villinError = error{
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
        cb: *const fn(*StreamContext, []const u8) villinError!void,

        pub fn init(ctx: *StreamContext, callback: *const fn(*StreamContext, []const u8) villinError!void) @This() {
            return .{
                .ctx = ctx,
                .cb = callback,
            };
        }

        pub fn wrap(self: *const @This(), data: []const u8) villinError!void {
            try self.cb(self.ctx, data);
        }
    };

    pub const StreamHandler = struct {
        buffer: []u8,
        write_pos: usize,
        callback: *const fn([]const u8) villinError!void,

        pub fn init(allocator: std.mem.Allocator, size: usize, cb: *const fn([]const u8) villinError!void) !*StreamHandler {
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

    // [Rest of CompressEngine implementation...]
    // [All the same methods as before, just without the test blocks]
};