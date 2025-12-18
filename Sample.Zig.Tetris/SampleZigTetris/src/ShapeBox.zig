const std = @import("std");
const Shape = @import("Shape.zig");
const int2 = @import("int2.zig");
const E_SHAPE = @import("E_SHAPE.zig").E_SHAPE;
const SeedRandom = @import("SeedRandom.zig");

const assert = std.debug.assert;

const ShapeBox = @This();

_random: SeedRandom,
_currIdx: usize,
_currShape: *const RotatedShape,
_nextShape: *const RotatedShape,

pub fn Init(seed: u64) ShapeBox {
    var random = SeedRandom.Init(seed);
    var ret = ShapeBox{
        ._random = random,
        ._currShape = undefined,
        ._nextShape = undefined,
        ._currIdx = 0,
    };

    const curr = _GetRandomShape(&random);
    const next = _GetRandomShape(&random);
    ret._currShape = curr;
    ret._nextShape = next;

    return ret;
}

fn _GetRandomShape(random: *SeedRandom) *const RotatedShape {
    const idx = random.NextUsize(1, PRE_ROTATED_SHAPES.len);
    const shape = &PRE_ROTATED_SHAPES[@intCast(idx)];
    return shape;
}

pub fn SetNextShape(self: *ShapeBox) void {
    self._currIdx = 0;
    self._currShape = self._nextShape;
    self._nextShape = _GetRandomShape(&self._random);
}

pub fn Rotate(self: *ShapeBox) void {
    self._currIdx = self._GetRotateIndex();
}

pub fn GetCurrShape(self: *const ShapeBox) *const Shape {
    return &self._currShape.arr[self._currIdx];
}

pub fn GetCurrRotateShape(self: *const ShapeBox) *const Shape {
    return &self._currShape.arr[self._GetRotateIndex()];
}

pub fn GetNextShape(self: *const ShapeBox) *const Shape {
    return &self._nextShape.arr[0];
}

// ===============================================================================
// ===============================================================================

fn _GetRotateIndex(self: *const ShapeBox) usize {
    if (self._currIdx < self._currShape.len - 1) {
        return self._currIdx + 1;
    }

    return 0;
}

const RotatedShape = struct {
    arr: [4]Shape,
    len: usize,
};

const SHAPE_POINTS_L = [_]int2{
    int2.init(-1, 0),
    int2.init(0, 0),
    int2.init(1, 0),
    int2.init(1, 1),
};
const SHAPE_POINTS_J = [_]int2{
    int2.init(-1, 0),
    int2.init(0, 0),
    int2.init(1, -1),
    int2.init(1, 0),
};
const SHAPE_POINTS_T = [_]int2{
    int2.init(0, -1),
    int2.init(0, 0),
    int2.init(0, 1),
    int2.init(1, 0),
};
const SHAPE_POINTS_S = [_]int2{
    int2.init(0, 0),
    int2.init(0, 1),
    int2.init(1, -1),
    int2.init(1, 0),
};
const SHAPE_POINTS_Z = [_]int2{
    int2.init(0, -1),
    int2.init(0, 0),
    int2.init(1, 0),
    int2.init(1, 1),
};
const SHAPE_POINTS_I = [_]int2{
    int2.init(-1, 0),
    int2.init(0, 0),
    int2.init(1, 0),
    int2.init(2, 0),
};
const SHAPE_POINTS_O = [_]int2{
    int2.init(-1, -1),
    int2.init(-1, 0),
    int2.init(0, -1),
    int2.init(0, 0),
};

const SHAPE_L = Shape.Init(E_SHAPE.L, @constCast(&SHAPE_POINTS_L));
const SHAPE_J = Shape.Init(E_SHAPE.J, @constCast(&SHAPE_POINTS_J));
const SHAPE_T = Shape.Init(E_SHAPE.T, @constCast(&SHAPE_POINTS_T));
const SHAPE_S = Shape.Init(E_SHAPE.S, @constCast(&SHAPE_POINTS_S));
const SHAPE_Z = Shape.Init(E_SHAPE.Z, @constCast(&SHAPE_POINTS_Z));
const SHAPE_I = Shape.Init(E_SHAPE.I, @constCast(&SHAPE_POINTS_I));
const SHAPE_O = Shape.Init(E_SHAPE.O, @constCast(&SHAPE_POINTS_O));

const PRE_ROTATED_SHAPES: [8]RotatedShape = [_]RotatedShape{
    RotatedShape{
        .arr = [_]Shape{
            undefined,
            undefined,
            undefined,
            undefined,
        },
        .len = 4,
    },
    RotatedShape{
        .arr = [_]Shape{
            SHAPE_L,
            SHAPE_L._InternalRotate(),
            SHAPE_L._InternalRotate()._InternalRotate(),
            SHAPE_L._InternalRotate()._InternalRotate()._InternalRotate(),
        },
        .len = 4,
    },
    RotatedShape{
        .arr = [_]Shape{
            SHAPE_J,
            SHAPE_J._InternalRotate(),
            SHAPE_J._InternalRotate()._InternalRotate(),
            SHAPE_J._InternalRotate()._InternalRotate()._InternalRotate(),
        },
        .len = 4,
    },
    RotatedShape{
        .arr = [_]Shape{
            SHAPE_T,
            SHAPE_T._InternalRotate(),
            SHAPE_T._InternalRotate()._InternalRotate(),
            SHAPE_T._InternalRotate()._InternalRotate()._InternalRotate(),
        },
        .len = 4,
    },
    RotatedShape{
        .arr = [_]Shape{
            SHAPE_S,
            SHAPE_S._InternalRotate(),
            undefined,
            undefined,
        },
        .len = 2,
    },
    RotatedShape{
        .arr = [_]Shape{
            SHAPE_Z,
            SHAPE_Z._InternalRotate(),
            undefined,
            undefined,
        },
        .len = 2,
    },
    RotatedShape{
        .arr = [_]Shape{
            SHAPE_I,
            SHAPE_I._InternalRotate(),
            undefined,
            undefined,
        },
        .len = 2,
    },
    RotatedShape{
        .arr = [_]Shape{
            SHAPE_O,
            undefined,
            undefined,
            undefined,
        },
        .len = 1,
    },
};
