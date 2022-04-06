const std = @import("std");
const net = @import("net");
const s2s = @import("s2s");
const zenet = @import("zenet");
const ev = @import("events");
const utils = @import("utils.zig");

const T1 = struct {
    age: u32
};

const T2 = struct {
    weight: u64
};

const T3 = struct{};

pub fn main() !void {
    //try s2sPlayground();
    // try netPlayground();
    try netPlayground2Peer();
    // try fookerPlayground();
    // try packetPlayground();
    //try idPlayground();
}

pub fn packetPlayground() !void {
    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // var allocator = gpa.allocator();
    // _ = allocator;

    // const T1 = struct {};
    // const T2 = struct {
    //     age: u16,
    //     weight: u16,
    // };
    // const T3 = struct {};

    // var val1 = T2{.age = 10, .weight = 20};
    // net.data.registerTypes(.{T1, T2, T3});

    // var packet1 = try net.data.PacketInfo(T2).init(val1);
    // var data = std.ArrayList(u8).init(allocator);
    // defer data.deinit();
    // try packet1.serialize(data.writer());

   
    // var stream = std.io.fixedBufferStream(data.items);
    // var id = try s2s.deserialize(stream.reader(), u16);
    // if(id == 1) {
    //     var deserialized = try net.data.PacketInfo(T2).deserialize(stream.reader());
    //     std.log.debug("{} \n {}", .{packet1, deserialized});
    // }

    // var packet = try zenet.Packet.create(data.items, .{});
    // defer packet.destroy();
    // std.log.debug("{} {}", .{data.items.len, packet.dataLength});
}

pub fn s2sPlayground() !void {
//     var gpa = std.heap.GeneralPurposeAllocator(.{}){};
//     var allocator = gpa.allocator();


//     const Type2 = struct {
//         val: u16,
//     };

//     const Type1 = struct {
//         packetId: u16,
//         age: u16,
//         weight: u16,
//         t2: *Type2,
//     };

//     var t2ptr = try allocator.create(Type2);
//     t2ptr.* = Type2{.val = 10};
//     defer allocator.destroy(t2ptr);

//     var val1 = Type1{
//             .packetId = 1, .age = 20, .weight = 68 ,
//             .t2 = t2ptr,
//         };

//     var data = std.ArrayList(u8).init(allocator);
//     defer data.deinit();

//     for(data.items) |value, i| {
//          std.log.debug("{}: {}", .{i, value});
//     }

//     try s2s.serialize(data.writer(), Type1, val1);

//     var stream = std.io.fixedBufferStream(data.items);
//     // var deserialized = try s2s.deserializeAlloc(stream.reader(), Type1, allocator);
//     // defer s2s.free(allocator, Type1, &deserialized);

//     var deserialized = try s2s.deserializeAlloc(stream.reader(), Type1, allocator);
//     defer s2s.free(allocator, Type1, &deserialized);

//     std.log.debug("after deserialize", .{});
//     std.log.debug("{}", .{val1});
//     std.log.debug("{}", .{deserialized});
}

fn asd(comptime T: type, value: T) void{
    std.log.debug("asd {}", .{value});
}


fn t1PacketCallback(value: T1) !void {
    std.log.debug("T1 callback {}", .{value});
}


fn t2PacketCallback(value: T1) !void {
    std.log.debug("T2 callback {}", .{value});
}

pub fn packetReceived(value: net.data.PacketReceivedData) void {
    std.log.debug("GOT SHIT {}", .{value.container.id});
    switch(value.container.id) {
        utils.typeId(T1) => {
            var info = net.data.PacketInfo(T1).deserializeRaw(value.container);
            std.log.debug("T1: {}", info);
        },
        utils.typeId(T2) => {
            var info = net.data.PacketInfo(T1).deserializeRaw(value.container);
            std.log.debug("T2: {}", info);
        },
        else => unreachable,
    }
}

pub const Callbacks = struct {
    dispatcher: ev.Dispatcher
};

pub fn fooker(comptime T: type) fn (*Callbacks) void {
     return (struct {
        pub fn shit(thing: *Callbacks) void {
            thing.dispatcher.trigger(T, 10);
            // std.log.debug("I know the type... {s}, thing: {}\n", .{ @typeName(T), thing });
        }
     }.shit);
}

pub fn printU32(value: u32) void {
    std.log.debug("printU32 {}", .{value});
}

pub fn printU8(value: u8) void {
    std.log.debug("printI64 {}", .{value});
}

pub fn fookerPlayground() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();
    
    var callbacks = Callbacks{
        .dispatcher = ev.Dispatcher.init(allocator)
    };
    defer callbacks.dispatcher.deinit();

    callbacks.dispatcher.sink(u32).connect(printU32);
    callbacks.dispatcher.sink(u8).connect(printU8);

    var func1 = fooker(u32);
    var func2 = fooker(u8);

    magic(func1, &callbacks);
    magic(func2, &callbacks);
}

pub fn magic(fun: fn(*Callbacks) void, callbacks: *Callbacks) void {
    fun(callbacks);
}


pub fn serverT1Handler(value: T1) void {
    std.log.debug("Got T1 Server {}", .{value});
}


pub fn clientT1Handler(value: T1) void {
    std.log.debug("Got T1 Client {}", .{value});
}

pub fn netPlayground() !void {
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

    try server.registerPacketHandler(T1, serverT1Handler);
    try client.registerPacketHandler(T1, clientT1Handler);
    
    var lastTime = std.time.milliTimestamp();
    var timeAccumulatorSeconds: f64 = 0;
    var sendTimerAccumulator1: f64 = 0;
    var sendTimerAccumulator2: f64 = 0;
    const ticksPerSecond: f64 = 60.0;
    const tickPerSecondTime: f64 = 1.0/ticksPerSecond;
    std.log.debug("Started", .{});

    while(true) {
        var currentTime = std.time.milliTimestamp();
        var deltaTime: f64 = @intToFloat(f64, currentTime - lastTime) / 1000.0;  
        lastTime = currentTime;

        timeAccumulatorSeconds += deltaTime;
        sendTimerAccumulator1 += deltaTime;
        sendTimerAccumulator2 += deltaTime;

        if(timeAccumulatorSeconds >= tickPerSecondTime) {
            timeAccumulatorSeconds = 0;
            try server.tick();
            try client.tick();

          if(sendTimerAccumulator1 >= 2) {
                sendTimerAccumulator1 = -999;
                try server.broadcast(T1{.age = 10}, .{});
                std.log.debug("Server: broadcast", .{});
            }

            if(sendTimerAccumulator2 >= 2) {
                sendTimerAccumulator2 = -999;
                // var packetInfo1 = try net.data.PacketInfo(T1).init();
                try client.send(T1{.age = 20}, .{});
                std.log.debug("Client: send", .{});
            }
        }

    }
}


pub fn netPlayground2Peer() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();
    
    try net.init();
    defer net.deinit();

    var server = try net.conn.Server.create(allocator, 8081, .{});
    defer server.destroy();
    try server.registerPacketHandler(T1, serverT1Handler);

    var client = try net.conn.Client.create(allocator, "127.0.0.1", 8081);
    defer client.destroy();
    try client.registerPacketHandler(T1, clientT1Handler);
    try client.connect();


    var client2 = try net.conn.Client.create(allocator, "127.0.0.1", 8081);
    defer client2.destroy();
    try client2.connect();
    try client2.registerPacketHandler(T1, clientT1Handler);
  
    
    var lastTime = std.time.milliTimestamp();
    var timeAccumulatorSeconds: f64 = 0;
    var sendTimerAccumulator1: f64 = 0;
    var sendTimerAccumulator2: f64 = 0;
    const ticksPerSecond: f64 = 60.0;
    const tickPerSecondTime: f64 = 1.0/ticksPerSecond;
    std.log.debug("Started", .{});

    while(true) {
        var currentTime = std.time.milliTimestamp();
        var deltaTime: f64 = @intToFloat(f64, currentTime - lastTime) / 1000.0;  
        lastTime = currentTime;

        timeAccumulatorSeconds += deltaTime;
        sendTimerAccumulator1 += deltaTime;
        sendTimerAccumulator2 += deltaTime;

        if(timeAccumulatorSeconds >= tickPerSecondTime) {
            timeAccumulatorSeconds = 0;
            try server.tick();
            try client.tick();
            try client2.tick();

          if(sendTimerAccumulator1 >= 5) {
                sendTimerAccumulator1 = -999;
                // try server.send(T1{.age = 10}, .{});
                try server.send(1, T1{.age = 200}, .{});
                try server.send(1, T1{.age = 201}, .{});
                try server.send(2, T1{.age = 99}, .{});
                try server.send(0, T1{.age = 99}, .{});
            }

            if(sendTimerAccumulator2 >= 2) {
                sendTimerAccumulator2 = -999;
            //     try client.send(T1{.age = 20}, .{});
            //     std.log.debug("Client: send", .{});
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
