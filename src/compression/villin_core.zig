cont std = @import("std");

pub const CompressEngine = struct {
	allocator: std.mem.Allocator,
	config: CompressConfig,
	metrics: ?*Metrics,
	stream: ?*StreamHandler,  // New: Optimal streaming support

	pub const CompressConfig = struct {
		pattern_threashold: f64 = 0.95,
		min_pattern_length: usize = 4,
		mat_pattern_length: usize = 1024,
		window_size: usize = 4096,
		stream_buffer_size: usize = 8192, // New: Stream buffer configuration
	}; 

	
	// New: Stream handling component
	pub const StreamHandler = struct {
		buffer: []u8,	// holds incoming data
		write_pos: usize,	// Current write position
		callback: *const fn([]const u8) error{StreamError}!void, // Output handler

		// Initializing streaming
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
	
	pub fn write(self: *StreamHandler, data: []const u8) !void{
		if (self.write_pos + data.len > self.buffer.len) {
			try self.flush();
		}

		@memcpy(self.buffer[self.write_pos..][0..data.len], data);
		self.write_pos += data.len;
	}

		// Process buffer data
		pub fn flush(self: *StreamHandler) !void {
			if(self.write_pos == 0) return;
			try self.callback(self.buffer[0..self.write_pos]);
			self.write_pos = 0; 
		}

		// Cleanup
		pub fn deinit(self: *StreamHandler, allocator: std.mem.Allocator) void {
			allocator.free(self.buffer);
			allocator.destroy(self);
		}
	};
// Initialize compression engine
// !* conveys -> does not point to
// checks whether the pointer is NULL - essentially verifies that it does not point toa valid memory location
pub fn init(allocator: std.mem.Allocator, config: CompressConfig) !*CompressEngine{
	consts engine =  try allocator.create(CompressEngine);
	engine.*= .{
		.allocator = allocator,
		.config = config,
		.metrics = null,
		.stream = null,
	};
	return engine;
}


}

