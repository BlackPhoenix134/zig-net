const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const s2s_pkg = std.build.Pkg{
        .name = "s2s",
        .path = .{ .path = "libs/s2s/src/s2s.zig" },
    };

    const zenet_pkg = std.build.Pkg{
        .name = "zenet",
        .path = .{ .path = "libs/zenet/src/zenet.zig" },
    };

    const events_pkg = std.build.Pkg{
        .name = "events",
        .path = .{ .path = "libs/events/src/events.zig" },
    };

    const zig_net_pkg = std.build.Pkg{
        .name = "net",
        .path = .{ .path = "src/net.zig" },
        .dependencies = &[_]std.build.Pkg {
                s2s_pkg, zenet_pkg, events_pkg
        },
    };


    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    const main_exe = b.addExecutable("main", "src/main.zig");
    main_exe.setTarget(target);
    main_exe.setBuildMode(mode);
    main_exe.want_lto = false;
    main_exe.install();

    const main_run = main_exe.run();
    const main_run_step = b.step("run", "Runs main");
    main_run_step.dependOn(&main_run.step);

    main_exe.addPackage(zig_net_pkg);
    @import("libs/zenet/build.zig").link(b, main_exe);
    main_exe.addPackage(zenet_pkg);
    main_exe.addPackage(s2s_pkg);
    main_exe.addPackage(events_pkg);
}


pub fn link(b: *std.build.Builder, step: *std.build.LibExeObjStep) void {
    const path = @src().file;
    const last_idx = path.len - "/build.zig".len;
    const project_dir = path[0..last_idx+1];

    const s2s_pkg = std.build.Pkg{
        .name = "s2s",
        .path = .{ .path = project_dir ++ "libs/s2s/src/s2s.zig" },
    };

    const zenet_pkg = std.build.Pkg{
        .name = "zenet",
        .path = .{ .path = project_dir ++ "libs/zenet/src/zenet.zig" },
    };

    const events_pkg = std.build.Pkg{
        .name = "events",
        .path = .{ .path = project_dir ++ "libs/events/src/events.zig" },
    };

    const zig_net_pkg = std.build.Pkg{
        .name = "net",
        .path = .{ .path = project_dir ++ "src/net.zig" },
        .dependencies = &[_]std.build.Pkg {
                s2s_pkg, zenet_pkg, events_pkg
        },
    };
    
    _ = b;
    step.addPackage(zig_net_pkg);
}