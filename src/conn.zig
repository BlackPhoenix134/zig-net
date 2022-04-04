const std = @import("std");
const zenet = @import("zenet");
const data = @import("data.zig");
const s2s = @import("s2s");
const ev = @import("events");
const utils = @import("utils.zig");

fn createZenetPacket(allocator: std.mem.Allocator, packet_info: anytype) !*zenet.Packet {
    // var buffer: [255]u8 = undefined; //ToDo: find a smart way to limit buffer length at runtime (calc size of packet info), because otherwise it sends the whole thing
    var buffer = std.ArrayList(u8).init(allocator);
    defer buffer.deinit(); //bytes are copied, clearing buffer is fine ToDo: reuse buffer
    try packet_info.serialize(buffer.writer());
    return try zenet.Packet.create(buffer.items, .{});
    // // var stream = std.io.fixedBufferStream(&buffer);
    // try packetInfo.serialize(stream.writer());
    // return try zenet.Packet.create(&buffer, .{});
}

fn deserializationCapture(comptime T: type) fn (*ev.Dispatcher, []u8) anyerror!void {
     return (struct {
        pub fn handler(dispatcher: *ev.Dispatcher, buffer: []u8) !void {
            var stream = std.io.fixedBufferStream(buffer);
            var value = try s2s.deserialize(stream.reader(), T); 
            dispatcher.trigger(T, value);
        }
     }.handler);
}


pub const Server = struct {
    const Self = @This();
    allocator: std.mem.Allocator,
    address: zenet.Address,
    host: *zenet.Host,
    client_connected_signal: *ev.Signal(u32),
    client_disconnected_signal: *ev.Signal(u32),

    packet_received_dispatcher: ev.Dispatcher,
    packet_deserializer: std.AutoHashMap(u32, (fn (*ev.Dispatcher, []u8) anyerror!void)),

    pub fn create(allocator: std.mem.Allocator, port: u16) !*Self {
        var ptr = try allocator.create(Self);
        var address: zenet.Address = std.mem.zeroes(zenet.Address);
        address.host = zenet.HOST_ANY;
        address.port = port;
        var host = try zenet.Host.create(address, 1, 1, 0, 0);
        ptr.* = .{
            .allocator = allocator,
            .address = address,
            .host = host,
            .client_connected_signal = ev.Signal(u32).create(allocator),
            .client_disconnected_signal = ev.Signal(u32).create(allocator),
            .packet_received_dispatcher = ev.Dispatcher.init(allocator),
            .packet_deserializer = std.AutoHashMap(u32, (fn (*ev.Dispatcher, []u8) anyerror!void)).init(allocator),
            };
        return ptr;
    }

    pub fn destroy(self: *Self) void {
        self.packet_deserializer.deinit();
        self.packet_received_dispatcher.deinit();
        self.client_disconnected_signal.deinit();
        self.client_connected_signal.deinit();
        self.host.destroy();
        self.allocator.destroy(self);
    }

    //broadcasts to all peers connected
    pub fn broadcast(self: *Self, packet_info: anytype) !void {
        var packet = try createZenetPacket(self.allocator, packet_info); //ToDo: cleanup
        self.host.broadcast(0, packet);
    }

    pub fn tick(self: *Self) !void {
        var event: zenet.Event = std.mem.zeroes(zenet.Event);
        while (try self.host.service(&event, 0)) {
            if (event.peer == null)
                continue;
            switch (event.type) {
                .connect => {
                    std.log.debug(
                        "A new client connected from {d}:{d}.",
                        .{ event.peer.?.address.host, event.peer.?.address.port },
                    );
                    self.client_connected_signal.publish(123);
                },
                .receive => {
                    if (event.packet) |packet| {
                        std.log.debug(
                            "A packet of length {d} was received from {s} on channel {d}.",
                            .{ packet.dataLength, event.peer.?.data, event.channelID },
                        );

                        var data_pointer: [*]u8 = packet.data.?;
                        var length = packet.dataLength;
                        var buffer = data_pointer[0..length];
                        try self.onPacketReceived(buffer);

                        packet.destroy();
                    }
                },
                .disconnect => {
                    std.log.debug("{s} disconnected.", .{event.peer.?.data});
                    event.peer.?.data = null;
                    self.client_disconnected_signal.publish(456);
                },
                else => {
                    std.log.debug("ugh!", .{});
                },
            }
        }
    }

    pub fn registerPacketHandler(self: *Self, comptime T: type, handler: fn(T) void) !void {
        self.packet_received_dispatcher.sink(T).connect(handler);
        const typeId = utils.typeId(T);
        if(!self.packet_deserializer.contains(typeId)) {
            var deserialize_func = deserializationCapture(T);
            try self.packet_deserializer.put(typeId, deserialize_func);
            std.log.debug("registerd handler for {}", .{T});
        }
    }

    fn onPacketReceived(self: *Self, buffer: []u8) !void {
        var stream = std.io.fixedBufferStream(buffer);
        var id = try s2s.deserialize(stream.reader(), u32);
        var handler_maybe = self.packet_deserializer.get(id);

        if(handler_maybe) |handler| {
            // try handler(&self.packet_received_dispatcher, buffer[@sizeOf(u32)..buffer.len]);
           try handler(&self.packet_received_dispatcher, buffer[stream.pos..buffer.len]);
        }   
        else {
            std.log.info("No handler registered for packet id {}", .{id});
        }
    }
};

pub const Client = struct {
    const Self = @This();
    allocator: std.mem.Allocator,
    address: zenet.Address,
    client: *zenet.Host = null,
    peer: ?*zenet.Peer = null,

    connected_signal: *ev.Signal(u32),
    disconnected_signal: *ev.Signal(u32),

    packet_received_dispatcher: ev.Dispatcher,
    packet_deserializer: std.AutoHashMap(u32, (fn (*ev.Dispatcher, []u8) anyerror!void)),

    pub fn create(allocator: std.mem.Allocator, host: [*:0]const u8, port: u16) !*Self {
        var ptr = try allocator.create(Self);
        var address: zenet.Address = std.mem.zeroes(zenet.Address);
        try address.set_host(host);
        var client = try zenet.Host.create(null, 1, 1, 0, 0);
        address.port = port;
        ptr.* = .{
            .allocator = allocator,
            .address = address,
            .client = client,
            .connected_signal = ev.Signal(u32).create(allocator),
            .disconnected_signal = ev.Signal(u32).create(allocator),
            .packet_received_dispatcher = ev.Dispatcher.init(allocator),
            .packet_deserializer = std.AutoHashMap(u32, (fn (*ev.Dispatcher, []u8) anyerror!void)).init(allocator),
            };
        return ptr;
    }

    pub fn destroy(self: *Self) void {
        self.packet_deserializer.deinit();
        self.packet_received_dispatcher.deinit();
        self.disconnected_signal.deinit();
        self.connected_signal.deinit();
        self.client.destroy();
        self.allocator.destroy(self);
    }

    pub fn connect(self: *Self) !void {
        self.peer = try self.client.connect(self.address, 1, 0);
        var event: zenet.Event = std.mem.zeroes(zenet.Event);
        if (try self.client.service(&event, 5000)) {
            if (event.type == zenet.EventType.connect) {
                std.log.debug("Connection to 127.0.0.1:7777 succeeded!", .{});
                self.connected_signal.publish(123);
            }
        }
    }

    pub fn disconnect(self: *Self) !void {
        self.peer.disconnect(0);
        var event: zenet.Event = std.mem.zeroes(zenet.Event);
        while (try self.client.service(&event, 3000)) {
            switch (event.type) {
                .receive => {
                    if (event.packet) |packet| { //Dispose everything we receive while disconnecting
                        packet.destroy();
                    }
                },
                .disconnect => {
                    std.log.debug("Disconnect succeeded!", .{});
                    self.disconnected_signal.publish(456);
                },
                else => {},
            }
        }
    }

    //send to server
    pub fn send(self: *Self, packet_info: anytype) !void {
        var packet = try createZenetPacket(self.allocator, packet_info); //ToDo: cleanup
        self.client.broadcast(0, packet);
    }

    pub fn tick(self: *Self) !void {
        var event: zenet.Event = std.mem.zeroes(zenet.Event);
        while (try self.client.service(&event, 0)) {
            switch (event.type) {
                .receive => {
                    if (event.packet) |packet| {
                        std.log.debug("A packet of length {d} was received from {d}:{d} on channel {d}.", .{
                            packet.dataLength,
                            event.peer.?.address.host,
                            event.peer.?.address.port,
                            event.channelID,
                        });

                        var data_pointer: [*]u8 = packet.data.?;
                        var length = packet.dataLength;
                        var buffer = data_pointer[0..length];
                        try self.onPacketReceived(buffer);
                        packet.destroy();
                    }
                },
                else => {},
            }
        }
    }

    pub fn registerPacketHandler(self: *Self, comptime T: type, handler: fn(T) void) !void {
        self.packet_received_dispatcher.sink(T).connect(handler);
        const typeId = utils.typeId(T);
        if(!self.packet_deserializer.contains(typeId)) {
            var deserialize_func = deserializationCapture(T);
            try self.packet_deserializer.put(typeId, deserialize_func);
            std.log.debug("registerd handler for {}", .{T});
        }
    }

    fn onPacketReceived(self: *Self, buffer: []u8) !void {
        var stream = std.io.fixedBufferStream(buffer);
        var id = try s2s.deserialize(stream.reader(), u32);
        var handler_maybe = self.packet_deserializer.get(id);

        if(handler_maybe) |handler| {
            // try handler(&self.packet_received_dispatcher, buffer[@sizeOf(u32)..buffer.len]);
           try handler(&self.packet_received_dispatcher, buffer[stream.pos..buffer.len]);
        }   
        else {
            std.log.info("No handler registered for packet id {}", .{id});
        }
    }
};
