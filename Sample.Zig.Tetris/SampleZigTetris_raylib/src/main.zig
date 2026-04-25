const std = @import("std");
const builtin = @import("builtin");
const ray = @import("impl/raylib.zig").ray;

const Const = @import("impl/Const.zig");
const Time = @import("impl/Time.zig");
const Game = @import("impl/Game.zig");

// extern "c" fn _getch() u8;
// _ = _getch();

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;

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

fn _MakeGame(allocator: std.mem.Allocator) Game {
    if (builtin.mode == .Debug) {
        return Game.Init(allocator, 100);
    } else {
        var threaded_io: std.Io.Threaded = .init_single_threaded;
        const io = threaded_io.io();
        defer threaded_io.deinit();

        const time_now = std.Io.Clock.now(.awake, io).toNanoseconds();
        return Game.Init(allocator, @intCast(time_now));
    }
}
