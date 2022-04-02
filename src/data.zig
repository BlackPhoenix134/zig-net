const std = @import("std");
const zenet = @import("zenet");
const s2s = @import("s2s");

pub fn PacketInfo(comptime T: type) type {
    return struct {
        const Self = @This();
        id: u16,
        value: T,

        pub fn init(id: u16, value: T) Self {
            return Self{
                .id = id,
                .value = value,
            };
        }

        pub fn serialize(self: *Self, stream: anytype) !void {
              try s2s.serialize(stream, Self, self.*);
        }

        //does not support pointers/slices etc,.. which require an alloce (ToDo:)
         pub fn deserialize(stream: anytype) !Self {
              return try s2s.deserialize(stream, Self);
        }
    };
}