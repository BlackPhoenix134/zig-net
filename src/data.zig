const std = @import("std");
const zenet = @import("zenet");
const s2s = @import("s2s");


pub fn registerTypes(tuple: anytype) void {
    const fields = @typeInfo(@TypeOf(tuple)).Struct.fields;
    comptime var id_counter = 0;
    inline for (fields) |field| {
        comptime var value = @field(tuple, field.name);
        var id = typeIdHandle(value);
        if (id.* == std.math.maxInt(u16)) {
            id.* = id_counter;
            id_counter += 1;
            std.log.debug("registered {} with id {}", .{value, id.*});
        } 
    }
}

pub fn typeId(comptime T: type) !u16 {
    var id = typeIdHandle(T);
    if (id.* == std.math.maxInt(u16)) {
        return error.NotRegistered;
    }
    return id.*;
}

pub fn typeIdHandle(comptime T: type) *u16 {
    _ = T;
    return &(struct {
        pub var handle: u16 = std.math.maxInt(u16);
    }.handle);
}


pub fn PacketInfo(comptime T: type) type {
    return struct {
        const Self = @This();
        id: u16,
        value: T,

        pub fn init(value: T) !Self {
            var id = try typeId(T);
            return Self{
                .id = id,
                .value = value,
            };
        }

        //serializes id + value, not the struct itself
        pub fn serialize(self: *const Self, stream: anytype) !void {
            try s2s.serialize(stream, u16, self.id);
            try s2s.serialize(stream, T, self.value);
        }

        //needs to provide ad and serializes only value from stream (fetch id first), does not support pointers/slices etc,.. which require an alloce (ToDo:)
        pub fn deserialize(stream: anytype) !Self {
            var id = try typeId(T);
            var value = try s2s.deserialize(stream, T);
            return Self {
                .id = id,
                .value = value,
            };
        }
    };
}