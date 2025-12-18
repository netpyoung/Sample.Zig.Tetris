const std = @import("std");
const builtin = @import("builtin");
const ray = @import("impl/raylib.zig").ray;

const Const = @import("impl/Const.zig");
const Time = @import("impl/Time.zig");
const Game = @import("impl/Game.zig");

// extern "c" fn _getch() u8;
// _ = _getch();

pub fn main() !void {
    const allocator = init_allocator();
    defer deinit_allocator();

    ray.SetConfigFlags(ray.FLAG_WINDOW_RESIZABLE);

    ray.InitWindow(Const.WINDOW_WIDTH, Const.WINDOW_HEIGHT, Const.WINDOW_TITLE);
    defer ray.CloseWindow();

    ray.SetTargetFPS(99);
    //ray.SetTargetFPS(60);
    ray.InitAudioDevice();

    var time = Time.Init(60);
    var game: Game = _MakeGame(allocator);
    defer game.Deinit(allocator);

    while (!ray.WindowShouldClose()) {
        time.Update();

        while (time.ShouldTick()) : (time.ConsumeTick()) {
            game.UpdateKey();
            game.FixedUpdate(time.fixed_dt);
        }

        ray.BeginDrawing();
        {
            ray.ClearBackground(ray.DARKBROWN);
            {
                game.Render();
            }
            ray.DrawFPS(10, 10);
        }
        ray.EndDrawing();
    }
}

// ===============================================================================
// ===============================================================================

var gpa_instance = std.heap.GeneralPurposeAllocator(.{
    .thread_safe = true,
    .never_unmap = true,
    .retain_metadata = true,
    .stack_trace_frames = 16,
}){};

fn init_allocator() std.mem.Allocator {
    if (builtin.mode == .Debug or builtin.mode == .ReleaseSafe) {
        return gpa_instance.allocator();
    } else {
        return std.heap.page_allocator;
    }
}

fn deinit_allocator() void {
    if (builtin.mode == .Debug or builtin.mode == .ReleaseSafe) {
        const leaked = gpa_instance.deinit();
        if (leaked == .leak) {
            std.debug.print("\nMemory leak detected!\n", .{});
        }
    }
}

fn _MakeGame(allocator: std.mem.Allocator) Game {
    if (builtin.mode == .Debug) {
        return Game.Init(allocator, 100);
    } else {
        return Game.Init(allocator, @intCast(std.time.nanoTimestamp()));
    }
}
