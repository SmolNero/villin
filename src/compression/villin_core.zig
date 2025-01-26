cont std = @import("std");

pub const CompressEngine = struct {
	allocator: std.mem.Allocator,
	config: ComressConfig,
	metrics: ?*Metrics,
	stream: ?*StreamHandler,  // New: Optimal streaming support

	pub const CompressConfig = struct {

	}




}

