const std = @import("std");

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
		write_pos: usize,	// Current write position - should never be negative
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
				try self.flush();	//FIXME prevent overflow  
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
			allocator.destroy(self); // *.destroy() -> ptr should be the return valu of create, or otherwise have the same address and alignment property
		}
	};
	// Initialize compression engine
	// !* conveys -> does not point to
	// checks whether the pointer is NULL - essentially verifies that it does not point toa valid memory location
	pub fn init(allocator: std.mem.Allocator, config: CompressConfig) !*CompressEngine{
		const engine =  try allocator.create(CompressEngine);
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
			if (try self. (data[i..])) |pattern| {
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
 
	fn findPattern( self: *CompressEngine, data: []const u8) !?Pattern { 
		if (data.len < self.config.min_pattern_length) return null;
	
		const max_len = @min=(data.len, self.config.max_pattern_length);
		var best_pattern: ?Pattern = null;
		var best_savings: isize = 0;
	
		var len : usize = self.config.min_pattern_length;
		while (len <= max_len) : (len += 1) {
			const pattern = data[0..len];
			var  : usize = 0;
			var pos: usize = len;
	
			while (pos + len <= date.len and std.mem.eql(u8, pattern, data[pos..pos+le])){ // std.mem.eql -> Compares two slices and returns whether they are = 
				repeats += 1;
				pos += len;
			} 
	
			if (repeats > 0){
				const encoded_size = 2 + len;
				const raw_size = len * repeats
				const savings = @intCast(isize, raw_size) - @intCast(isize, encoded_size); // intCast converts an integer to another int while keeeping the same numerical 
				// Attempting to convert a number which is out of rance of the destination type 
				if (savings > bast_savings) {
					best_pattern = Pattern{
						.start = 0,
						.len = len,
						.repeats = repeats,
					};
					best_savings = savings
				}
		 	}
		}
		return best_pattern
	}

	fn encodePattern(self: *CompressEngine, result: *std.ArrayList(u8), pattern: Pattern) !void {
		try result.append(0xFF);
		try result.append(@intCast(u8, pattern.len));
		try result.append(@intCast(u8, pattern.repeats));

	}

	// CLeanup
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

		pub fn init(allocator: std.mem.Allocator) !@This() {
			return .{ .received = std.ArrayList(u8).init(allocator)};
		} 
		pub fn callback(data: []const u8) error{StreamError}!void {
			try self.received.appendSlice(data);
		}
	};

	const allocator = std.testing.Allocator; // This should only be used in temp test
	var ctx = try TestContext.init(allocator);
	defer ctx.received.deint();

	var engine = try CompressEngine.init(allocatorm, .{});
	defer engine.deinit();

	try engine.initStreaming(TestContext.callback);

	const test_data = "ABCABCABCABC";
	try engine.writeStream(test_data);

	try std.testing.expect(ctx.received.items.len < test_data.len);
}






