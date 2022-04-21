const std = @import("std");
const net = @import("net");
const s2s = @import("s2s");
const zenet = @import("zenet");
const ev = @import("events");


pub fn main() !void {
    var ga = std.testing.allocator;
    var it = try std.process.argsWithAllocator(ga);
    defer it.deinit();
    _ = it.skip(); //exe
    var startup_param_maybe = it.next();
    
    if(startup_param_maybe) |startup_param| {
        std.log.debug("{s}", .{startup_param});

        if(std.mem.eql(u8, startup_param, "server")) {
            std.log.debug("starting as dedicated server", .{});
            
        } else if(std.mem.eql(u8, startup_param, "client")) {
            std.log.debug("starting and connecting to localhost", .{});
            
        }
    } else {
        std.log.debug("Default startup mode", .{});
    }
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