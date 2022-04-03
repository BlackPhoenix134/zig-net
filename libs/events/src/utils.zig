const std = @import("std");

pub fn typeId(comptime T: type) u32 {
    return utils.hashStringFnv(u32, @typeName(T));
}

pub fn hashStringDjb2(comptime str: []const u8) comptime_int {
    var hash: comptime_int = 5381;
    for (str) |c| {
        hash = ((hash << 5) + hash) + @intCast(comptime_int, c);
    }
    return hash;
}

pub fn hashStringFnv(comptime ReturnType: type, comptime str: []const u8) ReturnType {
    std.debug.assert(ReturnType == u32 or ReturnType == u64);

    const prime = if (ReturnType == u32) @as(u32, 16777619) else @as(u64, 1099511628211);
    var value = if (ReturnType == u32) @as(u32, 2166136261) else @as(u64, 14695981039346656037);
    for (str) |c| {
        value = (value ^ @intCast(u32, c)) *% prime;
    }
    return value;
}