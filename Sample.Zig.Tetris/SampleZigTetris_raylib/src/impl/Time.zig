const ray = @import("raylib.zig").ray;

const TARGET_FPS = 60;

const Time = @This();

fixed_dt: f64,
_accumulator: f64,
_prev: f64,

pub fn Init(target_fps: u32) Time {
    const fixed_dt: f64 = 1.0 / @as(f64, @floatFromInt(target_fps));
    return Time{
        .fixed_dt = fixed_dt,
        ._accumulator = 0,
        ._prev = ray.GetTime(),
    };
}

pub fn Update(self: *Time) void {
    const now = ray.GetTime();
    const frameTime = now - self._prev;
    self._prev = now;
    self._accumulator += frameTime;
}

pub fn ShouldTick(self: Time) bool {
    return self._accumulator >= self.fixed_dt;
}

pub fn ConsumeTick(self: *Time) void {
    self._accumulator -= self.fixed_dt;
}
