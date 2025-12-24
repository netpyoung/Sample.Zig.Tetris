const sdl = @import("sdl.zig").sdl;

pub const WINDOW_TITLE = "Hello Zig Tetris";
pub const WINDOW_WIDTH = 400;
pub const WINDOW_HEIGHT = 600;

pub const FIELD_WIDTH = 10;
pub const FIELD_HEIGHT = 20;

pub const BLOCK_SIZE = 25;
pub const SEC_PER_PROCESS_GAME_INIT = 1;

pub const COLOR_L = sdl.SDL_Color{ .r = 128, .g = 0, .b = 128, .a = 255 };
pub const COLOR_J = sdl.SDL_Color{ .r = 255, .g = 255, .b = 255, .a = 255 };
pub const COLOR_T = sdl.SDL_Color{ .r = 255, .g = 255, .b = 0, .a = 255 };
pub const COLOR_S = sdl.SDL_Color{ .r = 0, .g = 255, .b = 0, .a = 255 };
pub const COLOR_Z = sdl.SDL_Color{ .r = 0, .g = 255, .b = 255, .a = 255 };
pub const COLOR_I = sdl.SDL_Color{ .r = 255, .g = 0, .b = 0, .a = 255 };
pub const COLOR_O = sdl.SDL_Color{ .r = 0, .g = 0, .b = 255, .a = 255 };
pub const COLOR_BACKGROUND = sdl.SDL_Color{ .r = 0, .g = 0, .b = 0, .a = 255 };