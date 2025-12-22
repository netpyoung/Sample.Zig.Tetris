const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const root_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const dep_SampleZigTetris = b.dependency("dep_SampleZigTetris", .{
        .target = target,
        .optimize = optimize,
    });
    root_module.addImport("SampleZigTetris", dep_SampleZigTetris.module("mod_SampleZigTetris"));

    const exe = b.addExecutable(.{
        .name = "SampleZigTetris_raylib",
        .root_module = root_module,
    });

    {
        // raylib
        const raylib_path = b.path("../../raylib");
        root_module.addIncludePath(try raylib_path.join(b.allocator, "include"));
        root_module.addLibraryPath(try raylib_path.join(b.allocator, "lib"));

        if (optimize == .Debug) {
            const link_opts: std.Build.Module.LinkSystemLibraryOptions = .{
                .preferred_link_mode = .dynamic,
                .search_strategy = .mode_first,
                .use_pkg_config = .no,
            };

            // link raylib
            root_module.linkSystemLibrary("raylib", link_opts);

            // install raylib.dll
            if (builtin.os.tag == .windows) {
                const dll = try raylib_path.join(b.allocator, "lib/raylib.dll");
                b.installBinFile(dll.src_path.sub_path, "raylib.dll");
            } else if (builtin.os.tag == .linux) {
                const so_path = try raylib_path.join(b.allocator, "lib/libraylib.so");
                const so_rpath = try std.fs.realpathAlloc(
                    b.allocator,
                    so_path.src_path.sub_path,
                );
                defer b.allocator.free(so_rpath);
                const so_rrpath = try std.fs.path.relative(b.allocator, ".", so_rpath);
                defer b.allocator.free(so_rrpath);

                b.installBinFile(so_rrpath, "libraylib.so");
            }
        } else {
            if (target.result.os.tag == .windows) {
                // hide console window
                exe.subsystem = .Windows;
                exe.entry = .{ .symbol_name = "mainCRTStartup" };

                const resolved_target = b.resolveTargetQuery(.{
                    .cpu_arch = .x86_64,
                    .os_tag = .windows,
                    .abi = .msvc,
                });
                root_module.resolved_target = resolved_target;

                const link_opts: std.Build.Module.LinkSystemLibraryOptions = .{
                    .preferred_link_mode = .static,
                    .search_strategy = .mode_first,
                    .use_pkg_config = .no,
                };

                // link raylib
                root_module.linkSystemLibrary("raylib", link_opts);

                // link others
                root_module.linkSystemLibrary("kernel32", link_opts);
                root_module.linkSystemLibrary("user32", link_opts);
                root_module.linkSystemLibrary("gdi32", link_opts);
                root_module.linkSystemLibrary("winmm", link_opts);
                root_module.linkSystemLibrary("shell32", link_opts);
            } else if (builtin.os.tag == .linux) {
                const link_opts: std.Build.Module.LinkSystemLibraryOptions = .{
                    .preferred_link_mode = .static,
                    .search_strategy = .mode_first,
                    .use_pkg_config = .no,
                };

                // link raylib
                root_module.linkSystemLibrary("raylib", link_opts);
            }
        }
    }
    exe.linkLibC();

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_unit_tests = b.addTest(.{
        .root_module = root_module,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);
    const test_step = b.step("test", "Run unit tests");
    {
        const raylib_path = b.path("../../raylib/");

        // install raylib.dll
        if (target.result.os.tag == .windows) {
            const dll = try raylib_path.join(b.allocator, "lib/raylib.dll");
            _ = try test_step.installFile(dll, "raylib.dll");
        } else if (target.result.os.tag == .linux) {
            const so_path = try raylib_path.join(b.allocator, "lib/libraylib.so");
            const so_rpath = try std.fs.realpathAlloc(
                b.allocator,
                so_path.src_path.sub_path,
            );
            defer b.allocator.free(so_rpath);

            _ = try test_step.installFile(.{ .cwd_relative = so_rpath }, "libraylib.so");
        }
    }
    test_step.dependOn(&run_exe_unit_tests.step);
}
