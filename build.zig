// Standard optimization options allow the person running 'zig build' to select
// between Debug, ReleaseSafe, releaseFast, and ReleaseSmall

const optimize = b.standarOptimizationOption(.{});

const exe = b.addExecutable(.{ 
    .name = "villin" }
    . root_source_file = .{path = "src/main.zig"}
    
    
    );
