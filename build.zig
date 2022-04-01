const std = @import("std");


const zenet_pkg = std.build.Pkg{
        .name = "zenet",
        .path = .{ .path = "libs/zenet/src/zenet.zig" },
};

const zig_net_pkg = std.build.Pkg{
    .name = "net",
    .path = .{ .path = "src/net.zig" },
};

const s2s_pkg = std.build.Pkg{
    .name = "s2s",
    .path = .{ .path = "libs/s2s/src/s2s.zig" },
};

pub fn build(b: *std.build.Builder) void {
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


    // var exe = b.addExecutable("network-main", "src/main.zig");
    // exe.install();

    // const run_cmd = exe.run();
    // run_cmd.step.dependOn(b.getInstallStep());
    // if (b.args) |args| {
    //     run_cmd.addArgs(args);
    // }

    // const run_step = b.step("run", "Run the app");
    // run_step.dependOn(&run_cmd.step);

    // const client_exe = b.addExecutable("zenet_test_client", "src/client.zig");
    // client_exe.setBuildMode(mode);
    // client_exe.setTarget(target);
    // client_exe.want_lto = false;
    // client_exe.addPackage(zenet_pkg);
    // client_exe.install();
    // const client_exe_run = client_exe.run();
    // const client_exe_run_step = b.step("client", "Runs client");
    // client_exe_run_step.dependOn(&client_exe_run.step);
    // @import("libs/zenet/build.zig").link(b, client_exe);

    // const server_exe = b.addExecutable("zenet_test_server", "src/server.zig");
    // server_exe.setBuildMode(mode);
    // server_exe.setTarget(target);
    // server_exe.want_lto = false;
    // server_exe.addPackage(zenet_pkg);
    // server_exe.step.dependOn(&b.addInstallArtifact(client_exe).step);
    // server_exe.install();
    // const server_exe_run =  server_exe.run();
    // const server_exe_run_step = b.step("server", "Runs server");
    // server_exe_run_step.dependOn(&server_exe_run.step);
    // @import("libs/zenet/build.zig").link(b, server_exe);
}