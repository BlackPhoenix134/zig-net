const std = @import("std");
const net = @import("net");
const s2s = @import("s2s");
const zenet = @import("zenet");
const ev = @import("events");


pub fn main() !void {
    try netPlayground();
}


pub fn netPlayground() !void {
    std.log.debug("alarm", .{});
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();
    _ = allocator;
    try net.init();
    defer net.deinit();
}