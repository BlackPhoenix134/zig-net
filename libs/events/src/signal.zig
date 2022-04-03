const std = @import("std");
const Sink = @import("sink.zig").Sink;
const Delegate = @import("delegate.zig").Delegate;

pub fn Signal(comptime Event: type) type {
    return struct {
        const Self = @This();

        calls: std.ArrayList(Delegate(Event)),
        allocator: ?std.mem.Allocator = null,

        pub fn init(allocator: std.mem.Allocator) Self {
            // we purposely do not store the allocator locally in this case so we know not to destroy ourself in deint!
            return Self{
                .calls = std.ArrayList(Delegate(Event)).init(allocator),
            };
        }

        /// heap allocates a Signal
        pub fn create(allocator: std.mem.Allocator) *Self {
            var signal = allocator.create(Self) catch unreachable;
            signal.calls = std.ArrayList(Delegate(Event)).init(allocator);
            signal.allocator = allocator;
            return signal;
        }

        pub fn deinit(self: *Self) void {
            self.calls.deinit();

            // optionally destroy ourself as well if we came from an allocator
            if (self.allocator) |allocator| allocator.destroy(self);
        }

        pub fn size(self: Self) usize {
            return self.calls.items.len;
        }

        pub fn empty(self: Self) bool {
            return self.size == 0;
        }

        /// Disconnects all the listeners from a signal
        pub fn clear(self: *Self) void {
            self.calls.items.len = 0;
        }

        pub fn publish(self: Self, arg: Event) void {
            for (self.calls.items) |call| {
                call.trigger(arg);
            }
        }

        /// Constructs a sink that is allowed to modify a given signal
        pub fn sink(self: *Self) Sink(Event) {
            return Sink(Event).init(self);
        }
    };
}
