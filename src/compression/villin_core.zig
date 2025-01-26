cont std = @import("std");

pub const CompressEngine = struct {
	allocator: std.mem.Allocator,
	config: ComressConfig,
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
	pub const StreamHandler = struct {}




}

