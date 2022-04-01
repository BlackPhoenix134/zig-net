const std = @import("std");
const zenet = @import("zenet");

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
    };
}