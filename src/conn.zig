const std = @import("std");
const zenet = @import("zenet");
const data = @import("data");

pub const Server = struct {
    const Self = @This();
    allocator: std.mem.Allocator,
    address: zenet.Address,
    host: *zenet.Host,
    
    pub fn create(allocator: std.mem.Allocator, port: u16) !*Self {
        var ptr = try allocator.create(Self);
        var address: zenet.Address = std.mem.zeroes(zenet.Address);
        address.host = zenet.HOST_ANY;
        address.port = port;
        var host = try zenet.Host.create(address, 1, 1, 0, 0);
        ptr.* = .{ .allocator = allocator, .address = address, .host = host };
        return ptr;
    }

    pub fn destroy(self: *Self) void {
        self.host.destroy();
        self.allocator.destroy(self);
    }


    // pub fn broadcast(self: *Self) void {
        
    // }

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
                },
                .receive => {
                    if (event.packet) |packet| {
                        std.log.debug(
                            "A packet of length {d} was received from {s} on channel {d}.",
                            .{ packet.dataLength, event.peer.?.data, event.channelID },
                        );
                        packet.destroy();
                    }
                },
                .disconnect => {
                    std.log.debug("{s} disconnected.", .{event.peer.?.data});
                    event.peer.?.data = null;
                },
                else => {
                    std.log.debug("ugh!", .{});
                },
            }
        }
    }
};

pub const Client = struct {
    const Self = @This();
    allocator: std.mem.Allocator,
    address: zenet.Address,
    client: *zenet.Host = null,
    peer: ?*zenet.Peer = null,

    pub fn create(allocator: std.mem.Allocator, host: [*:0]const u8, port: u16) !*Self {
        var ptr = try allocator.create(Self);
        var address: zenet.Address = std.mem.zeroes(zenet.Address);
        try address.set_host(host);
        var client = try zenet.Host.create(null, 1, 1, 0, 0);
        address.port = port;
        ptr.* = .{ .allocator = allocator, .address = address, .client = client };
        return ptr;
    }

    pub fn destroy(self: *Self) void {
        self.client.destroy();
        self.allocator.destroy(self);
    }

    pub fn connect(self: *Self) !void {
        self.peer = try self.client.connect(self.address, 1, 0);

        var event: zenet.Event = std.mem.zeroes(zenet.Event);
        if (try self.client.service(&event, 5000)) {
            if (event.type == zenet.EventType.connect) {
                std.log.debug("Connection to 127.0.0.1:7777 succeeded!", .{});
            }
        }
    }

    pub fn disconnect(self: *Self) !void {
        self.peer.disconnect(0);

        var event: zenet.Event = std.mem.zeroes(zenet.Event);
        while (try self.client.service(&event, 3000)) {
            switch (event.type) {
                .receive => {
                    if (event.packet) |packet| {
                        packet.destroy();
                    }
                },
                .disconnect => {
                    std.log.debug("Disconnect succeeded!", .{});
                },
                else => {},
            }
        }
    }

    // pub fn send(self: *Self, packet: data.Packet) !void {

    // }

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
                    }
                },
                else => {},
            }
        }
    }
};
