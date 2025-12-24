const std = @import("std");
const sdl = @import("sdl.zig").sdl;
const Shape = @import("SampleZigTetris").Shape;
const Table = @import("SampleZigTetris").Table;
const int2 = @import("SampleZigTetris").int2;
const E_SHAPE = @import("SampleZigTetris").E_SHAPE;
const GameState = @import("SampleZigTetris").GameState;

const Const = @import("Const.zig");
const Keyboard = @import("Keyboard.zig");
const Timer = @import("Timer.zig");

const Game = @This();
_gameState: GameState,
_keyboard: Keyboard,
_logicTimer: Timer,

pub var SdlStuff = SdlStuffContainer{
    .font = undefined,
    .surface = undefined,
    .texture = undefined,
};

const SdlStuffContainer = struct {
    font: *sdl.TTF_Font,
    surface: *sdl.SDL_Surface,
    texture: *sdl.SDL_Texture,

    pub fn Init(self: *SdlStuffContainer, renderer: *sdl.SDL_Renderer) !void {
        if (!sdl.TTF_Init()) {
            std.debug.print("{s}", .{sdl.SDL_GetError()});
            return error.FAIL_TTF_INIT;
        }

        const font = sdl.TTF_OpenFont("arial.ttf", 30);

        const color = sdl.SDL_Color{ .r = 255, .g = 0, .b = 0, .a = 255 };
        const msg = "GAME OVER";

        const surface = sdl.TTF_RenderText_Solid(font, msg, msg.len, color);
        if (surface == null) {
            std.debug.print("{s}", .{sdl.SDL_GetError()});
            return error.FAIL_TTF_RENDERTEXTURE;
        }

        const texture = sdl.SDL_CreateTextureFromSurface(renderer, surface);
        if (texture == null) {
            std.debug.print("{s}", .{sdl.SDL_GetError()});
            return error.FAIL_CREATE_TEXTURE;
        }

        self.font = font.?;
        self.surface = surface.?;
        self.texture = texture.?;
    }
    pub fn Deinit(self: *SdlStuffContainer) void {
        sdl.SDL_DestroyTexture(self.texture);
        sdl.SDL_DestroySurface(self.surface);
        sdl.TTF_CloseFont(self.font);
        sdl.TTF_Quit();
    }
};

pub fn Init(allocator: std.mem.Allocator, seed: u64) Game {
    const gameState = GameState.Init(allocator, seed, Const.FIELD_WIDTH, Const.FIELD_HEIGHT);
    const keyboard = Keyboard.init();
    const ret = Game{
        ._gameState = gameState,
        ._keyboard = keyboard,
        ._logicTimer = Timer.Init(1),
    };

    return ret;
}

pub fn Deinit(self: *Game, allocator: std.mem.Allocator) void {
    self._gameState.Deinit(allocator);
}

pub fn SetKeyDown(self: *Game, key: u32, isDown: bool) void {
    self._keyboard.SetKeyDown(key, isDown);
}

pub fn UpdateKey(self: *Game) void {
    self._keyboard.Update();
}

pub fn FixedUpdate(self: *Game, dt: f64) void {
    if (self._gameState.IsGameOver()) {
        return;
    }

    self.ProcessInput(dt);
    self._gameState.ProcessCommand(GameState.E_COMMAND.UPDATE_SHADOW_POS);

    if (!self._logicTimer.Tick(dt)) {
        return;
    }
    self._gameState.ProcessCommand(GameState.E_COMMAND.SOFT_DROP_TICK);
}

pub fn Render(self: *Game, renderer: *sdl.SDL_Renderer) void {
    const table = self._gameState.GetTable();
    _RenderTable(renderer, table);

    if (!self._gameState.IsGameOver()) {
        _RenderShape(renderer, self._gameState.GetCurrentPos(), self._gameState.GetCurrShape());
        if (self._gameState.GetShadowPosOrNull()) |shadowPos| {
            _RenderShadowShape(renderer, shadowPos, self._gameState.GetCurrShape());
        }

        _RenderShape(renderer, int2.init(12, 2), self._gameState.GetNextShape());
        return;
    }

    // render GameOver
    const textWidth = SdlStuff.texture.w;
    const x = Const.WINDOW_WIDTH / 2 - @divTrunc(textWidth, 2);
    const y = Const.WINDOW_HEIGHT / 3;
    const r = sdl.SDL_FRect{
        .x = @floatFromInt(x),
        .y = @floatFromInt(y),
        .w = @floatFromInt(SdlStuff.texture.w),
        .h = @floatFromInt(SdlStuff.texture.h),
    };
    _ = sdl.SDL_RenderTexture(renderer, SdlStuff.texture, null, &r);
}

// ===============================================================================
// ===============================================================================
fn ProcessInput(self: *Game, dt: f64) void {
    _ = dt;

    if (self._keyboard.IsKeyPressed(Keyboard.E_KEY.LEFT)) {
        self._gameState.ProcessCommand(GameState.E_COMMAND.LEFT);
    }

    if (self._keyboard.IsKeyPressed(Keyboard.E_KEY.RIGHT)) {
        self._gameState.ProcessCommand(GameState.E_COMMAND.RIGHT);
    }

    if (self._keyboard.IsKeyPressed(Keyboard.E_KEY.DOWN)) {
        self._gameState.ProcessCommand(GameState.E_COMMAND.DOWN);
    }

    if (self._keyboard.IsKeyPressed(Keyboard.E_KEY.ROTATE)) {
        self._gameState.ProcessCommand(GameState.E_COMMAND.ROTATE);
    }

    if (self._keyboard.IsKeyPressed(Keyboard.E_KEY.DROP)) {
        self._gameState.ProcessCommand(GameState.E_COMMAND.DROP);
    }
}

fn _RenderTable(renderer: *sdl.SDL_Renderer, table: *const Table) void {
    const r_bg = sdl.SDL_FRect{
        .x = 0,
        .y = 0,
        .w = Const.BLOCK_SIZE * Const.FIELD_WIDTH,
        .h = Const.BLOCK_SIZE * Const.FIELD_HEIGHT,
    };

    _ = sdl.SDL_SetRenderDrawColor(renderer, Const.COLOR_BACKGROUND.r, Const.COLOR_BACKGROUND.g, Const.COLOR_BACKGROUND.b, Const.COLOR_BACKGROUND.a);
    _ = sdl.SDL_RenderFillRect(renderer, &r_bg);

    // render shape
    const screenOffset = 2;
    var r_shape: sdl.SDL_FRect = undefined;
    r_shape.w = Const.BLOCK_SIZE - screenOffset;
    r_shape.h = Const.BLOCK_SIZE - screenOffset;
    var iter = table.iterate();
    while (iter.next()) |item| {
        const e = item.e;
        if (e == E_SHAPE.NONE) {
            continue;
        }

        const x = item.x;
        const y = item.y;
        const color = _E_SHAPE_ToColor(e);
        const screenX: f32 = @floatFromInt(x * Const.BLOCK_SIZE + screenOffset);
        const screenY: f32 = @floatFromInt(y * Const.BLOCK_SIZE + screenOffset);
        r_shape.x = screenX;
        r_shape.y = screenY;
        _ = sdl.SDL_SetRenderDrawColor(renderer, color.r, color.g, color.b, color.a);
        _ = sdl.SDL_RenderFillRect(renderer, &r_shape);
    }
}

fn _RenderShape(renderer: *sdl.SDL_Renderer, pos: int2, shape: *const Shape) void {
    __RenderShape(renderer, pos, shape, 255);
}

fn _RenderShadowShape(renderer: *sdl.SDL_Renderer, pos: int2, shape: *const Shape) void {
    __RenderShape(renderer, pos, shape, 128);
}

fn __RenderShape(renderer: *sdl.SDL_Renderer, pos: int2, shape: *const Shape, alpha: u8) void {
    var r: sdl.SDL_FRect = undefined;
    const screenOffset = 2;

    r.w = Const.BLOCK_SIZE - screenOffset;
    r.h = Const.BLOCK_SIZE - screenOffset;

    const e = shape.name;
    var color = _E_SHAPE_ToColor(e);
    color.a = alpha;

    _ = sdl.SDL_SetRenderDrawBlendMode(renderer, sdl.SDL_BLENDMODE_BLEND);
    var iter = shape.iterate();
    while (iter.next()) |p| {
        const x = pos.x + p.x;
        const y = pos.y + p.y;

        const screenX: f32 = @floatFromInt(x * Const.BLOCK_SIZE + screenOffset);
        const screenY: f32 = @floatFromInt(y * Const.BLOCK_SIZE + screenOffset);
        r.x = screenX;
        r.y = screenY;

        _ = sdl.SDL_SetRenderDrawColor(renderer, color.r, color.g, color.b, color.a);
        _ = sdl.SDL_RenderFillRect(renderer, &r);
    }
    _ = sdl.SDL_SetRenderDrawBlendMode(renderer, sdl.SDL_BLENDMODE_NONE);
}

fn _E_SHAPE_ToColor(eShape: E_SHAPE) sdl.SDL_Color {
    return switch (eShape) {
        E_SHAPE.NONE => Const.COLOR_BACKGROUND,
        E_SHAPE.L => Const.COLOR_L,
        E_SHAPE.J => Const.COLOR_J,
        E_SHAPE.T => Const.COLOR_T,
        E_SHAPE.S => Const.COLOR_S,
        E_SHAPE.Z => Const.COLOR_Z,
        E_SHAPE.I => Const.COLOR_I,
        E_SHAPE.O => Const.COLOR_O,
    };
}
