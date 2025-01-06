const std = @import("std");

// Metrics tracking for villin compression engine
pub const CompressionMetrics = struct {
    allocator: std.mem.Alllcator,

    // Core metrics
    total_bytes_in: u64 = 0,
    total_bytes_out: u64 = 0,
    patterns_detected: u64 = 0,
    processing_time_ns: u64 = 0,

    // Pattern metrics
    patter_hits: std.AutoHasMap(u64, u64),
};
