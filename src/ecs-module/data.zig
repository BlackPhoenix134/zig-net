const std = @import("std");
const s2s = @import("s2s");
const ev = @import("events");

pub const SpawnEntityPacket = struct {

};

pub const SyncNowPacket = struct {
    entity_id: u32,
    component_data: []ComponentSyncData,
};

pub const ComponentSyncData = struct {
    component_id: u32,
    data: []u8
};

pub const SerializationHandler = struct {
    const Self = @This();
    allocator: std.mem.Allocator,
  
    packet_serializer_dispatcher: ev.Dispatcher,
    packet_deserializer_dispatcher: ev.Dispatcher,
    packet_serializer: std.AutoHashMap(u32, (fn (*ev.Dispatcher, []u8) anyerror!void)),
    packet_deserializer: std.AutoHashMap(u32, (fn (*ev.Dispatcher, []u8) anyerror!void)),

    pub fn create(allocator: std.mem.Allocator) !*Self {
        var ptr = try allocator.create(Self);
        ptr.* = .{
            .allocator = allocator,
            .packet_received_dispatcher = ev.Dispatcher.init(allocator),
            .packet_deserializer = std.AutoHashMap(u32, (fn (*ev.Dispatcher, []u8) anyerror!void)).init(allocator),
            };
        return ptr;
    }

    pub fn destroy(self: *Self) void {
        self.packet_deserializer.deinit();
        self.packet_received_dispatcher.deinit();
        self.allocator.destroy(self);
    }

   pub fn registerPacketHandler(self: *Self, comptime T: type, deserializer: fn(T) void, serializer: fn(T) void,) !void {
        self.packet_serializer_dispatcher.sink(T).connect(serializer);
        self.packet_deserializer_dispatcher.sink(T).connect(deserializer);
        const typeId = utils.typeId(T);
        if(!self.packet_deserializer.contains(typeId)) {
            var deserialize_func = deserializationCapture(T);
            try self.packet_deserializer.put(typeId, deserialize_func);
            std.log.debug("Server: registerd handler for {}", .{T});
        }
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
};