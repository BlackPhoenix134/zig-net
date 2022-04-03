const std = @import("std");
const zenet = @import("zenet");
const s2s = @import("s2s");
const utils = @import("utils.zig");

pub fn PacketInfo(comptime T: type) type {
    return struct {
        const Self = @This();
        id: u32 = utils.typeId(T),
        value: T,

        pub fn init(value: T) !Self {
            return Self{
                .value = value
            };
        }

        //serializes id + value, not the struct itself
        pub fn serialize(self: *const Self, stream: anytype) !void {
            try s2s.serialize(stream, u32, self.id);
            try s2s.serialize(stream, T, self.value);
        }

        //needs to provide ad and serializes only value from stream (fetch id first), does not support pointers/slices etc,.. which require an alloce (ToDo:)
        pub fn deserialize(stream: anytype) !Self {
            var value = try s2s.deserialize(stream, T);
            return Self {
                .value = value
            };
        }
    };
}

// pub fn typeId(comptime T: type) !u32 {
//     var id = typeIdHandle(T);
//     if (id.* == std.math.maxInt(u32)) {
//         return error.NotRegistered;
//     }
//     return id.*;
// }

// pub fn typeIdHandle(comptime T: type) *u32 {
//     _ = T;
//     return &(struct {
//         pub var handle: u32 = std.math.maxInt(u32);
//     }.handle);
// }

// pub fn TypePacketCallback(comptime T: type) type {
//   return struct {
//         const Self = @This();
//         id: u32,
//         callback: fn(T) anyerror!void,

//         pub fn init(callback: fn(T) anyerror!void) !Self {
//             var id = typeId(T);
//             return Self{
//                 .id = id,
//                 .callback = callback,
//             };
//         }

//         pub fn invoke(self: *Self, value: T) !void {
//             try self.callback(value);
//         }
//   };
// }
