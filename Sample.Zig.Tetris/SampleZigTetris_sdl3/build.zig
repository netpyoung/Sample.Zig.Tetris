const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const root_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const translate_c = b.addTranslateC(.{
        .root_source_file = b.path("src/c.h"),
        .target = target,
        .optimize = optimize,
    });

    const dep_SampleZigTetris = b.dependency("dep_SampleZigTetris", .{
        .target = target,
        .optimize = optimize,
    });

    if (target.result.os.tag == .windows) {
        {
            // install sdl
            const dynamic_link_opts: std.Build.Module.LinkSystemLibraryOptions = .{
                .preferred_link_mode = .dynamic,
                .search_strategy = .mode_first,
                .use_pkg_config = .no,
            };
            {
                const sdl_path = b.path("../../SDL3_lib/SDL3/");
                translate_c.addIncludePath(sdl_path.join(b.allocator, "include") catch unreachable);
                root_module.addLibraryPath(sdl_path.join(b.allocator, "lib/x64") catch unreachable);
                const bin = sdl_path.join(b.allocator, "lib/x64/SDL3.dll") catch unreachable;
                b.installBinFile(bin.src_path.sub_path, "SDL3.dll");
                root_module.linkSystemLibrary("SDL3", dynamic_link_opts);
            }
            {
                const sdl_path = b.path("../../SDL3_lib/SDL3_ttf/");
                translate_c.addIncludePath(sdl_path.join(b.allocator, "include") catch unreachable);
                root_module.addLibraryPath(sdl_path.join(b.allocator, "lib/x64") catch unreachable);
                const bin = sdl_path.join(b.allocator, "lib/x64/SDL3_ttf.dll") catch unreachable;
                b.installBinFile(bin.src_path.sub_path, "SDL3_ttf.dll");
                root_module.linkSystemLibrary("SDL3_ttf", dynamic_link_opts);
            }
        }
        {
            const font_file = b.addInstallFileWithDir(
                b.path("../../res/arial.ttf"),
                .bin,
                "arial.ttf",
            );
            b.getInstallStep().dependOn(&font_file.step);
        }
    }

    root_module.addImport("SampleZigTetris", dep_SampleZigTetris.module("mod_SampleZigTetris"));
    root_module.addImport("c", translate_c.createModule());
    root_module.link_libc = true;

    const exe = b.addExecutable(.{
        .name = "SampleZigTetris_sdl3",
        .root_module = root_module,
    });

    if (target.result.os.tag == .windows) {
        if (optimize != .Debug) {
            exe.subsystem = .Windows;
            exe.entry = .{ .symbol_name = "mainCRTStartup" };
        }
    }

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
