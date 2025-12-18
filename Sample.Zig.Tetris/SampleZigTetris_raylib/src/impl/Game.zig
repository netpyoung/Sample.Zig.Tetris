const std = @import("std");
const ray = @import("raylib.zig").ray;
const Shape = @import("SampleZigTetris").Shape;
const Table = @import("SampleZigTetris").Table;
const int2 = @import("SampleZigTetris").int2;
const E_SHAPE = @import("SampleZigTetris").E_SHAPE;
const GameState = @import("SampleZigTetris").GameState;

const Const = @import("Const.zig");
const Keyboard = @import("Keyboard.zig");
const Timer = @import("Timer.zig");

const assert = std.debug.assert;

const Game = @This();

_gameState: GameState,
_keyboard: Keyboard,
_logicTimer: Timer,

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

pub fn UpdateKey(self: *Game) void {
    self._keyboard.Update();
}

pub fn ProcessInput(self: *Game, dt: f64) void {
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

pub fn FixedUpdate(self: *Game, fixed_dt: f64) void {
    if (self._gameState.IsGameOver()) {
        return;
    }

    self.ProcessInput(fixed_dt);
    self._gameState.ProcessCommand(GameState.E_COMMAND.UPDATE_SHADOW_POS);

    if (!self._logicTimer.Tick(fixed_dt)) {
        return;
    }

    self._gameState.ProcessCommand(GameState.E_COMMAND.SOFT_DROP_TICK);
}

pub fn Render(self: *const Game) void {
    const table = self._gameState.GetTable();

    if (!self._gameState.IsGameOver()) {
        _RenderTable(table);
        _RenderShape(self._gameState.GetCurrentPos(), self._gameState.GetCurrShape());
        if (self._gameState.GetShadowPosOrNull()) |shadowPos| {
            _RenderShadowShape(shadowPos, self._gameState.GetCurrShape());
        }

        _RenderShape(int2.init(12, 2), self._gameState.GetNextShape());
        return;
    }

    _RenderTable(table);

    // render GameOver
    const text = ray.TextFormat("GAME OVER");
    const fontSize = 40;
    const textWidth = ray.MeasureText(text, fontSize);
    const x = Const.WINDOW_WIDTH / 2 - @divTrunc(textWidth, 2);
    const y = Const.WINDOW_HEIGHT / 3;
    ray.DrawText(text, x, y, fontSize, ray.RED);
}

// ===============================================================================
// ===============================================================================

fn _RenderTable(table: *const Table) void {
    {
        // render bg
        const r_bg = ray.Rectangle{
            .x = 0,
            .y = 0,
            .width = Const.BLOCK_SIZE * Const.FIELD_WIDTH,
            .height = Const.BLOCK_SIZE * Const.FIELD_HEIGHT,
        };
        ray.DrawRectangleRec(r_bg, Const.COLOR_BACKGROUND);
    }

    // render shape
    const screenOffset = 2;
    var r_shape: ray.Rectangle = undefined;
    r_shape.width = Const.BLOCK_SIZE - screenOffset;
    r_shape.height = Const.BLOCK_SIZE - screenOffset;

    for (0..table.height) |y| {
        for (0..table.width) |x| {
            const e: E_SHAPE = table.GetValue(x, y);
            if (e == E_SHAPE.NONE) {
                continue;
            }

            const color = _E_SHAPE_ToColor(e);
            const screenX: f32 = @floatFromInt(x * Const.BLOCK_SIZE + screenOffset);
            const screenY: f32 = @floatFromInt(y * Const.BLOCK_SIZE + screenOffset);
            r_shape.x = screenX;
            r_shape.y = screenY;

            ray.DrawRectangleRec(r_shape, color);
        }
    }
}

fn _RenderShape(pos: int2, shape: *const Shape) void {
    var r: ray.Rectangle = undefined;
    const screenOffset = 2;

    r.width = Const.BLOCK_SIZE - screenOffset;
    r.height = Const.BLOCK_SIZE - screenOffset;

    const e = shape.name;
    const color = _E_SHAPE_ToColor(e);

    for (shape.points[0..shape.pointlen]) |*p| {
        const x = pos.x + p.x;
        const y = pos.y + p.y;

        const screenX: f32 = @floatFromInt(x * Const.BLOCK_SIZE + screenOffset);
        const screenY: f32 = @floatFromInt(y * Const.BLOCK_SIZE + screenOffset);
        r.x = screenX;
        r.y = screenY;
        ray.DrawRectangleRec(r, color);
    }
}

fn _RenderShadowShape(pos: int2, shape: *const Shape) void {
    var r: ray.Rectangle = undefined;
    const screenOffset = 2;

    r.width = Const.BLOCK_SIZE - screenOffset;
    r.height = Const.BLOCK_SIZE - screenOffset;

    const e = shape.name;
    var color = _E_SHAPE_ToColor(e);
    color.a = 128;

    var iter = shape.iterate();
    while (iter.next()) |p| {
        const x = pos.x + p.x;
        const y = pos.y + p.y;

        const screenX: f32 = @floatFromInt(x * Const.BLOCK_SIZE + screenOffset);
        const screenY: f32 = @floatFromInt(y * Const.BLOCK_SIZE + screenOffset);
        r.x = screenX;
        r.y = screenY;
        ray.DrawRectangleRec(r, color);
    }
}

fn _E_SHAPE_ToColor(eShape: E_SHAPE) ray.struct_Color {
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
