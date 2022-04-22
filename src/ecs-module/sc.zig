const std = @import("std");
const net = @import("net");

pub const EcsConfig = struct {
    server_config: net.conn.ServerConfig = .{},
};

pub const EcsServer = struct {
    const Self = @This();
    allocator: std.mem.Allocator,
    server: *net.conn.Server,

    pub fn create(allocator: std.mem.Allocator, port: u16, config: EcsConfig) !*Self {
        var ptr = try allocator.create(Self);
        ptr.* = .{
            .allocator = allocator,
            .server = try net.conn.Server.create(allocator, port, config.server_config)
            };
        return ptr;
    }

    pub fn destroy(self: *Self) void {
        self.server.destroy();
        self.allocator.destroy(self);
    }

    pub fn tick(self: *Self) !void {
        try self.server.tick();
    }
};


pub const EcsClient = struct {
    const Self = @This();
    allocator: std.mem.Allocator,
    client: *net.conn.Client,

    pub fn create(allocator: std.mem.Allocator, hostIp: [*:0]const u8, port: u16) !*Self {
        var ptr = try allocator.create(Self);
        ptr.* = .{
            .allocator = allocator,
            .client = try net.conn.Client.create(allocator, hostIp, port),
            };
        return ptr;
    }

    pub fn destroy(self: *Self) void {
        self.client.destroy();
        self.allocator.destroy(self);
    }

    pub fn connect(self: *Self) !void {
        try self.client.connect();
    }

    pub fn disconnect(self: *Self) !void {
        try self.client.disconnect();
    }

    pub fn tick(self: *Self) !void {
        try self.client.tick();
    }
};