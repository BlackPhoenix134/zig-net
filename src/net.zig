const std = @import("std");
const zenet = @import("zenet");
pub const conn = @import("conn.zig");

pub fn init() !void {
   try zenet.initialize();
}

pub fn deinit() void {
    zenet.deinitialize();
}
