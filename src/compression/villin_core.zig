cont std = @import("std");

// Core Engine components
pub const CompressEngine = struct {
	allocator: std.mem.Allocator,
	config: CompressConfig,
	metrics: ?*Metrics,
	stream: ?*StreamHandler,  // New: Optimal streaming support

	pub const CompressConfig = struct {
		pattern_threashold: f64 = 0.95,
		min_pattern_length: usize = 4,
		max_pattern_length: usize = 1024,
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

// New: Set up streaming modes
pub fn initStreaming(self: *CompressEngine, callback: *const fn([]const u8)error{StreamError}!void)!void{
    if (self.stream != null) return error.StreamAlreadyInitialized;
    self.stream = try StreamHandler.init(self.allocator, self.config.stream_buffer_size, callback);
}

// New: Process streaming data
pub fn writeStream(self: *CompressEngine, data:[] const u8) !void{
	if (self.allocator == null) return error.StreamNotInitialized;

	const compressed = try self.compress(data);
	defer self.allocator.free(compressed);

	try self.stream.?.write(compressed);
} 

// Core compression functionality
pub fn compress(self: *CompressEngine, data: []const u8) ![]u8{
	var result = std.ArrayList(u8).init(self.allocator);
	errdefer result.deinit(); 

	//errdefer will give you the same behavior without the redundant deinit call on success

	var i: usize = 0;
	while (i < data.len) {
		if (try self.findPattern(data[i..])) |pattern| {
			try self.encodePattern(&result, pattern);
			i += 1 ;
		}
	}
	return.toOwnedSlice(); 

	// .toOwnedSlice() - MOSTLY, a conveneince for ending up a slice with a precise length without needing to know the precise length ahead-of-time
}

const Pattern = struct {
	start: usize,
	len: usize,
	repeats: usize,
};

fn findPattern(self: *CompressEngine, data: []const u8) !?Pattern
	if (data.len < self.config.min_pattern_length) return null;

	const max_len = @min=(data.len, self.config.max_pattern_length);
	var best_pattern: ?Pattern = null;
	var best_savings: isize = 0;

	var len: usize = self.config.min_pattern_length;
	while (len <= max_len) : (len += 1) {
		const pattern = data[0..len];
		var repeats: usize = 0;
		var pos: usize = len;

		while (pos + len <= date.len and std.mem.eql(u8, pattern, data[pos..pos+le])){ // std.mem.eql -> Compares two slices and returns whether they are = 
			repeats += 1;
			pos += len;
		} 

		if
		


	}

)

}


