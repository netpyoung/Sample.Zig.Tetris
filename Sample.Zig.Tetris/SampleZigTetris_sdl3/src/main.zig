const std = @import("std");
const builtin = @import("builtin");
const sdl = @import("impl/sdl.zig").sdl;

const Const = @import("impl/Const.zig");
const Time = @import("impl/Time.zig");
const Game = @import("impl/Game.zig");

const print = std.debug.print;

pub fn main() u8 {
    sdl.SDL_SetMainReady();

    if (!sdl.SDL_Init(sdl.SDL_INIT_VIDEO)) {
        std.debug.print("{s}", .{sdl.SDL_GetError()});
        return 1;
    }
    defer sdl.SDL_Quit();

    const window = sdl.SDL_CreateWindow(Const.WINDOW_TITLE, Const.WINDOW_WIDTH, Const.WINDOW_HEIGHT, 0);
    if (window == null) {
        std.debug.print("{s}", .{sdl.SDL_GetError()});
        return 1;
    }
    defer sdl.SDL_DestroyWindow(window);

    const renderer = sdl.SDL_CreateRenderer(window, null);
    if (renderer == null) {
        std.debug.print("{s}", .{sdl.SDL_GetError()});
        return 1;
    }
    defer sdl.SDL_DestroyRenderer(renderer);

    Game.SdlStuff.Init(renderer.?) catch unreachable;
    defer Game.SdlStuff.Deinit();

    const allocator = init_allocator();
    defer deinit_allocator();

    var time = Time.Init(60);
    var game: Game = _MakeGame(allocator);
    defer game.Deinit(allocator);

    mainloop: while (true) {
        time.Update();

        var sdl_event: sdl.SDL_Event = undefined;
        while (sdl.SDL_PollEvent(&sdl_event)) {
            switch (sdl_event.type) {
                sdl.SDL_EVENT_QUIT => break :mainloop,
                sdl.SDL_EVENT_KEY_DOWN => {
                    if (sdl_event.key.key == sdl.SDLK_ESCAPE) {
                        break :mainloop;
                    }
                    game.SetKeyDown(sdl_event.key.key, true);
                },
                sdl.SDL_EVENT_KEY_UP => {
                    game.SetKeyDown(sdl_event.key.key, false);
                },
                else => {},
            }
        }

        while (time.ShouldTick()) : (time.ConsumeTick()) {
            game.UpdateKey();
            game.FixedUpdate(time.fixed_dt);
        }

        // render
        _ = sdl.SDL_SetRenderDrawColor(renderer, 76, 63, 47, 255);
        _ = sdl.SDL_RenderClear(renderer);
        {
            game.Render(renderer.?);
        }
        _ = sdl.SDL_RenderPresent(renderer);
        _ = sdl.SDL_Delay(1);
    }

    return 0;
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
