const std = @import("std");

/// wraps either a free function or a bound function that takes an Event as a parameter
pub fn Delegate(comptime Event: type) type {
    return struct {
        const Self = @This();

        ctx_ptr_address: usize = 0,
        callback: fn(Event) void,


         pub fn containsFree(self: Self, callback: fn (Event) void) bool {
            return self.callback == callback;
        }

        pub fn initFree(func: fn (Event) void) Self {
            return Self{
                .callback = func,
            };
        }

        pub fn trigger(self: Self, param: Event) void {
            @call(.{}, self.callback, .{param});
        }
    };
}
