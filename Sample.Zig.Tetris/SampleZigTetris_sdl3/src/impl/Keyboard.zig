const std = @import("std");
const sdl = @import("sdl.zig").sdl;

const Keyboard = @This();

_isKeyDownBuff: [E_KEY.Count]bool,
_isKeyDownPrev: [E_KEY.Count]bool,
_isKeyDownCurr: [E_KEY.Count]bool,
_isKeyPressed: [E_KEY.Count]bool,
_isKeyReleased: [E_KEY.Count]bool,

pub const E_KEY = enum(usize) {
    pub const Count: usize = switch (@typeInfo(E_KEY)) {
        .@"enum" => |e| e.fields.len,
        else => @compileError("E_KEY must be an enum"),
    };

    LEFT = 0,
    RIGHT = 1,
    DOWN = 2,
    ROTATE = 3,
    DROP = 4,
};

pub fn init() Keyboard {
    return Keyboard{
        ._isKeyDownBuff = .{false} ** E_KEY.Count,
        ._isKeyDownPrev = .{false} ** E_KEY.Count,
        ._isKeyDownCurr = .{false} ** E_KEY.Count,
        ._isKeyPressed = .{false} ** E_KEY.Count,
        ._isKeyReleased = .{false} ** E_KEY.Count,
    };
}

pub fn Update(self: *Keyboard) void {
    for (0..E_KEY.Count) |i| {
        const e: E_KEY = @enumFromInt(i);
        self._isKeyDownCurr[i] = _IsKeyDown(self, e);
    }

    for (0..E_KEY.Count) |i| {
        if (self._isKeyDownCurr[i]) {
            if (!self._isKeyDownPrev[i]) {
                self._isKeyPressed[i] = true;
                continue;
            }
        }
        if (self._isKeyDownPrev[i]) {
            if (!self._isKeyDownCurr[i]) {
                self._isKeyReleased[i] = true;
                continue;
            }
        }
        self._isKeyPressed[i] = false;
        self._isKeyReleased[i] = false;
    }

    for (0..E_KEY.Count) |i| {
        self._isKeyDownPrev[i] = self._isKeyDownCurr[i];
    }
}

pub fn IsKeyDown(self: *const Keyboard, key: E_KEY) bool {
    const idx: usize = @intCast(@intFromEnum(key));
    return self._isKeyDownCurr[idx];
}

pub fn IsKeyPressed(self: *const Keyboard, key: E_KEY) bool {
    const idx: usize = @intCast(@intFromEnum(key));
    return self._isKeyPressed[idx];
}

pub fn IsKeyReleased(self: *const Keyboard, key: E_KEY) bool {
    const idx: usize = @intCast(@intFromEnum(key));
    return self._isKeyReleased[idx];
}

// ===============================================================================
// ===============================================================================

fn _ToRayKeyCode(key: E_KEY) i32 {
    switch (key) {
        E_KEY.LEFT => return sdl.SDLK_LEFT,
        E_KEY.RIGHT => return sdl.SDLK_RIGHT,
        E_KEY.DOWN => return sdl.SDLK_DOWN,
        E_KEY.ROTATE => return sdl.SDLK_UP,
        E_KEY.DROP => return sdl.SDLK_SPACE,
    }
}

fn _IsKeyDown(self: *const Keyboard, key: E_KEY) bool {
    return self._isKeyDownBuff[@intFromEnum(key)];
}

pub fn SetKeyDown(self: *Keyboard, key: u32, isDown: bool) void {
    switch (key) {
        sdl.SDLK_LEFT => {
            self._isKeyDownBuff[@intFromEnum(E_KEY.LEFT)] = isDown;
        },
        sdl.SDLK_RIGHT => {
            self._isKeyDownBuff[@intFromEnum(E_KEY.RIGHT)] = isDown;
        },
        sdl.SDLK_DOWN => {
            self._isKeyDownBuff[@intFromEnum(E_KEY.DOWN)] = isDown;
        },
        sdl.SDLK_UP => {
            self._isKeyDownBuff[@intFromEnum(E_KEY.ROTATE)] = isDown;
        },
        sdl.SDLK_SPACE => {
            self._isKeyDownBuff[@intFromEnum(E_KEY.DROP)] = isDown;
        },
        else => {},
    }
}
