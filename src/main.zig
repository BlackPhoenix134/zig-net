const std = @import("std");
const net = @import("net");

pub fn main() !void {
    std.log.debug("test", .{});
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();
    
    try net.init();
    defer net.deinit();

    var server = try net.conn.Server.create(allocator, 8081);
    defer server.destroy();

    var client = try net.conn.Client.create(allocator, "127.0.0.1", 8081);
    defer client.destroy();
    try client.connect();

    var lastTime = std.time.milliTimestamp();
    var timeAccumulatorSeconds: f64 = 0;
    var sendTimerAccumulator: f64 = 0;
    const ticksPerSecond: f64 = 1.0;
    const tickPerSecondTime: f64 = 1.0/ticksPerSecond;
    std.log.debug("Started", .{});

    while(true) {
        var currentTime = std.time.milliTimestamp();
        var deltaTime: f64 = @intToFloat(f64, currentTime - lastTime) / 1000.0;  
        lastTime = currentTime;

        timeAccumulatorSeconds += deltaTime;
        sendTimerAccumulator += deltaTime;

        if(timeAccumulatorSeconds >= tickPerSecondTime) {
            timeAccumulatorSeconds = 0;
            std.log.debug("tick server", .{});
            try server.tick();
            std.log.debug("tick tick", .{});
            try client.tick();

            if(sendTimerAccumulator >= 5) {
                sendTimerAccumulator = 0;
                std.log.debug("send packet", .{});
            }
        }
    }
}





// const std = @import("std");
// const network = @import("./network.zig");

// pub const io_mode = .evented;

// const Server = struct {
//     const Self = @This();
//     allocator: std.mem.Allocator,
//     socket: network.Socket,
//     socketSet: network.SocketSet,

//     pub fn create(allocator: std.mem.Allocator, port: u16) !*Self {
//         var ptr = try allocator.create(Self);
//         var socket = try network.Socket.create(.ipv4, .tcp);
//         try socket.bind(.{
//              .address = .{ .ipv4 = network.Address.IPv4.any },
//              .port = port,
//         });

//         ptr.* = .{
//             .allocator = allocator,
//             .socket = socket,
//             .socketSet = try network.SocketSet.init(allocator)
//         };
//         try ptr.socketSet.add(socket, .{.read = true, .write = true});
//         return ptr;
//     }

//     pub fn destroy(self: *Self) void {
//         self.socketSet.deinit();
//         self.socket.close();
//         self.allocator.destroy(self);
//     }

//     pub fn listen(self: *Self) !void {
//         try self.socket.listen();
//     }

//     pub fn tick(self: *Self) !void {
//         var size = try network.waitForSocketEvent(&self.socketSet, null);
//         if(size > 0) {
//             var readyRead = self.socketSet.isReadyRead(self.socket);
//             var readyWrite = self.socketSet.isReadyRead(self.socket);
//             std.log.debug("Size Server {} ready read {} ready write {} ", .{size, readyRead, readyWrite});
//         }
//     }
// };

// const Client = struct {
//     const Self = @This();
//     allocator: std.mem.Allocator,
//     socket: network.Socket,
//     socketSet: network.SocketSet,

//     pub fn create(allocator: std.mem.Allocator) !*Self {
//         var ptr = try allocator.create(Self);
//         var socket = try network.Socket.create(.ipv4, .tcp);
//         ptr.* = .{
//             .allocator = allocator,
//             .socket = socket,
//             .socketSet = try network.SocketSet.init(allocator)
//         };
//         return ptr;
//     }

//     pub fn destroy(self: *Self) void {
//         self.socketSet.deinit();
//         self.socket.close();
//         self.allocator.destroy(self);
//     }

//     pub fn connect(self: *Self, ipv4: network.Address.IPv4, port: u16) !void {
//         try self.socket.connect(.{
//             .address = .{ .ipv4 = ipv4 },
//             .port = port
//         });
//     }

//     pub fn tick(self: *Self) !void {
//         var size = try network.waitForSocketEvent(&self.socketSet, null);
//         if(size > 0) {
//             var readyRead = self.socketSet.isReadyRead(self.socket);
//             var readyWrite = self.socketSet.isReadyRead(self.socket);
//             std.log.debug("Size Client {} ready read {} ready write {} ", .{size, readyRead, readyWrite});
//         }
//     }

//     pub fn send(self: *Self) !void {
//         _ = try self.socket.send("test");
//     }
// };

// pub fn main() !void {
//     const allocator = std.heap.page_allocator;
    
//     var server = try Server.create(allocator, 8081);
//     defer server.destroy();
//     try server.listen();
    
//     var client = try Client.create(allocator);
//     defer client.destroy();
//     try client.connect(network.Address.IPv4.init(127, 0, 0, 1), 8081);
    
//     var lastTime = std.time.milliTimestamp();
//     var timeAccumulatorSeconds: f64 = 0;
//     const ticksPerSecond: f64 = 1.0;
//     const tickPerSecondTime: f64 = 1.0/ticksPerSecond;
//     var hasSend: bool = false;
//     std.log.debug("Started", .{});

//     while(true) {
//         var currentTime = std.time.milliTimestamp();
//         var deltaTime: f64 = @intToFloat(f64, currentTime - lastTime) / 1000.0;  
//         lastTime = currentTime;

//         timeAccumulatorSeconds += deltaTime;
//         if(timeAccumulatorSeconds >= tickPerSecondTime) {
//             timeAccumulatorSeconds = 0;
//             std.log.debug("pre tick", .{});
//             try server.tick();
//             try client.tick();

//             std.log.debug("post tick", .{});
//             if(!hasSend) {
//                 try client.send();
//                 hasSend = true;
//             }
//         }
//     }

// }

// // pub fn main() !void {
// //     const allocator = std.heap.page_allocator;

// //     try network.init();
// //     defer network.deinit();

// //     var server = try network.Socket.create(.ipv4, .tcp);
// //     defer server.close();

// //     try server.bind(.{
// //         .address = .{ .ipv4 = network.Address.IPv4.any },
// //         .port = 2501,
// //     });

// //     try server.listen();
// //     std.log.info("listening at {}\n", .{try server.getLocalEndPoint()});
// //     while (true) {
// //         std.debug.print("Waiting for connection\n", .{});
// //         const client = try allocator.create(Client);
// //         var conn = try server.accept();
// //         client.* = Client {
// //             .conn = conn,
// //             .handle_frame = async client.handle(),
// //         };
// //     }
// // }

// // const Client = struct {
// //     conn: network.Socket,
// //     handle_frame: @Frame(Client.handle),

// //     fn handle(self: *Client) !void {
// //         try self.conn.writer().writeAll("server: welcome to the chat server\n");

// //         while (true) {
// //             var buf: [100]u8 = undefined;
// //             const amt = try self.conn.receive(&buf);
// //             if (amt == 0)
// //                 break; // We're done, end of connection
// //             const msg = buf[0..amt];
// //             std.debug.print("Client wrote: {s}", .{msg});
// //         }
// //     }
// // };
