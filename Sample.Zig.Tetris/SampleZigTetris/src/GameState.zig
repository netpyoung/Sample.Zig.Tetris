const std = @import("std");

const Table = @import("Table.zig");
const ShapeBox = @import("ShapeBox.zig");
const Shape = @import("Shape.zig");
const int2 = @import("int2.zig");

const P_DOWN = int2.init(0, 1);

const GameState = @This();

_initialSeed: u64,
_table: Table,
_shapeBox: ShapeBox,
_initPos: int2,
_currPos: int2,
_shadowPosOrNull: ?int2,
_isGameOver: bool,

pub const E_COMMAND = enum {
    LEFT,
    RIGHT,
    DOWN,
    ROTATE,
    DROP,
    SOFT_DROP_TICK,
    UPDATE_SHADOW_POS,
};

pub fn Init(allocator: std.mem.Allocator, seed: u64, w: usize, h: usize) GameState {
    const initX = w / 2 - 1;
    const initY = 2;
    const initP = int2.init(@intCast(initX), @intCast(initY));
    const curP = initP;

    const table = Table.Init(allocator, w, h);
    const shapeBox = ShapeBox.Init(seed);
    const gameState = GameState{
        ._initialSeed = seed,
        ._table = table,
        ._shapeBox = shapeBox,
        ._initPos = initP,
        ._currPos = curP,
        ._shadowPosOrNull = null,
        ._isGameOver = false,
    };
    return gameState;
}

pub fn Deinit(self: *GameState, allocator: std.mem.Allocator) void {
    self._table.Deinit(allocator);
}

pub fn IsGameOver(self: *const GameState) bool {
    return self._isGameOver;
}

pub fn GetTable(self: *const GameState) *const Table {
    return &self._table;
}

pub fn GetCurrentPos(self: *const GameState) int2 {
    return self._currPos;
}

pub fn GetShadowPosOrNull(self: *const GameState) ?int2 {
    return self._shadowPosOrNull;
}

pub fn GetCurrShape(self: *const GameState) *const Shape {
    return self._shapeBox.GetCurrShape();
}

pub fn GetNextShape(self: *const GameState) *const Shape {
    return self._shapeBox.GetNextShape();
}

pub fn GetHardDropPosOrNull(self: *const GameState) ?int2 {
    const currShape = self._shapeBox.GetCurrShape();

    var tempP = self._currPos;
    while (true) {
        const moveP = tempP.add(P_DOWN);
        const moveShape = currShape.Add(moveP);
        if (self._table.IsCollision(&moveShape)) {
            break;
        }
        tempP = moveP;
    }

    if (tempP.equal(self._currPos)) {
        return null;
    }

    return tempP;
}

pub fn ProcessCommand(self: *GameState, cmd: E_COMMAND) void {
    switch (cmd) {
        E_COMMAND.LEFT => {
            _ = self._DoMove(int2.left);
        },
        E_COMMAND.RIGHT => {
            _ = self._DoMove(int2.right);
        },
        E_COMMAND.DOWN => {
            self._SoftDrop();
        },
        E_COMMAND.ROTATE => {
            _ = self._DoRotate();
        },
        E_COMMAND.DROP => {
            self._HardDrop();
        },
        E_COMMAND.SOFT_DROP_TICK => {
            self._SoftDropTick();
            self._shadowPosOrNull = self.GetHardDropPosOrNull();
        },
        E_COMMAND.UPDATE_SHADOW_POS => {
            self._shadowPosOrNull = self.GetHardDropPosOrNull();
        },
    }
}

// ===============================================================================
// ===============================================================================

fn _DoMove(self: *GameState, p: int2) bool {
    var movepOrNull: ?int2 = undefined;
    if (!self._TryMove(p, &movepOrNull)) {
        return false;
    }
    self._currPos = movepOrNull.?;
    return true;
}

fn _TryMove(self: *GameState, p: int2, outMovep: *?int2) bool {
    const currShape = self._shapeBox.GetCurrShape();
    const moveP = self._currPos.add(p);
    const moveShape = currShape.Add(moveP);
    if (self._table.IsCollision(&moveShape)) {
        outMovep.* = null;
        return false;
    }
    outMovep.* = moveP;
    return true;
}

fn _DoRotate(self: *GameState) bool {
    const curRotShape = self._shapeBox.GetCurrRotateShape();
    const shape = curRotShape.Add(self._currPos);
    if (self._table.IsCollision(&shape)) {
        return false;
    }

    self._shapeBox.Rotate();
    return true;
}

fn _SoftDrop(self: *GameState) void {
    _ = self._DoMove(P_DOWN);
}

fn _HardDrop(self: *GameState) void {
    while (self._DoMove(P_DOWN)) {}
    self._PutShape();
}

fn _SoftDropTick(self: *GameState) void {
    if (self._DoMove(P_DOWN)) {
        return;
    }

    self._PutShape();
}

fn _PutShape(self: *GameState) void {
    if (self._isGameOver) {
        return;
    }

    const currPos = self._currPos;
    const currShape = self._shapeBox.GetCurrShape();
    self._table.ShapeIntoTable(currPos, currShape);
    self._shapeBox.SetNextShape();
    self._currPos = self._initPos;

    const removedCount = self._table.RemoveFulledRows();
    _ = removedCount;

    var movep: ?int2 = undefined;
    if (self._TryMove(int2.zero, &movep)) {
        return;
    }
    self._isGameOver = true;
    std.debug.print("{f}\n\n", .{self._table});
}
