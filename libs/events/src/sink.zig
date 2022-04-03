const std = @import("std");
const Signal = @import("signal.zig").Signal;
const Delegate = @import("delegate.zig").Delegate;

/// helper used to connect and disconnect listeners on the fly from a Signal. Listeners are wrapped in Delegates
/// and can be either free functions or functions bound to a struct.
pub fn Sink(comptime Event: type) type {
    return struct {
        const Self = @This();

        insert_index: usize,

        /// the Signal this Sink is temporarily wrapping
        var owning_signal: *Signal(Event) = undefined;

        pub fn init(signal: *Signal(Event)) Self {
            owning_signal = signal;
            return Self{ .insert_index = owning_signal.calls.items.len };
        }

        pub fn connect(self: Self, callback: fn (Event) void) void {
            std.debug.assert(self.indexOf(callback) == null);
            _ = owning_signal.calls.insert(self.insert_index, Delegate(Event).initFree(callback)) catch unreachable;
        }


        pub fn disconnect(self: Self, callback: fn (Event) void) void {
            if (self.indexOf(callback)) |index| {
                _ = owning_signal.calls.swapRemove(index);
            }
        }


        fn indexOf(_: Self, callback: fn (Event) void) ?usize {
            for (owning_signal.calls.items) |call, i| {
                if (call.containsFree(callback)) {
                    return i;
                }
            }
            return null;
        }

        fn indexOfBound(_: Self, ctx: anytype) ?usize {
            for (owning_signal.calls.items) |call, i| {
                if (call.containsBound(ctx)) {
                    return i;
                }
            }
            return null;
        }
    };
}