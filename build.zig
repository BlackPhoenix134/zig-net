const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    const main_exe = b.addExecutable("main", "examples/main.zig");
    main_exe.setTarget(target);
    main_exe.setBuildMode(mode);
    main_exe.want_lto = false;
    main_exe.install();

    const main_run = main_exe.run();
    const main_run_step = b.step("run-main", "Runs main");
    main_run_step.dependOn(&main_run.step);

    link(b, main_exe, target, false);

    const main_flecs_exe = b.addExecutable("main_flecs", "examples/main_flecs.zig");
    main_flecs_exe.setTarget(target);
    main_flecs_exe.setBuildMode(mode);
    main_flecs_exe.want_lto = false;
    main_flecs_exe.install();

    const main_flecs_run = main_flecs_exe.run();

    const main_flecs_step = b.step("run-flecs", "Runs main_flecs");
    main_flecs_step.dependOn(&main_flecs_run.step);



    link(b, main_flecs_exe, target, true);
}

//ToDo: externaly provide flecs package, so you can choose version / dont have to have a copy of flecs in this lib folder
pub fn link(b: *std.build.Builder, step: *std.build.LibExeObjStep, target: std.zig.CrossTarget, comptime withFlecs: bool) void {
    const path = @src().file;
    const last_idx = path.len - "/build.zig".len;
    const project_dir = path[0 .. last_idx + 1];

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
    
    const zig_net_pkg = std.build.Pkg {
            .name = "net",
            .path = .{ .path = project_dir ++ "src/net.zig" },
            .dependencies = &[_]std.build.Pkg{ s2s_pkg, zenet_pkg, events_pkg },
    };

    const ecs_net_pkg = std.build.Pkg {
            .name = "ecs_net",
            .path = .{ .path = project_dir ++ "src/ecs-module/ecs_net.zig" },
            .dependencies = &[_]std.build.Pkg{ s2s_pkg, zenet_pkg, events_pkg, zig_net_pkg },
    };

    const zenet_builder = @import("libs/zenet/build.zig");
    zenet_builder.link(b, step);
    step.addPackage(zig_net_pkg);

    if (withFlecs) {
        step.addPackage(ecs_net_pkg);
        const flecs_builder = @import("libs/zig-flecs/build.zig");
        flecs_builder.linkArtifact(b, step, target, flecs_builder.LibType.static, project_dir ++ "libs/zig-flecs/");
    }
}
