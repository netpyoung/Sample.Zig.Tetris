const sdl = @import("sdl.zig").sdl;

const TARGET_FPS = 60;

const Time = @This();

fixed_dt: f64,
_freq: u64,
_accumulator: f64,
_prev: u64,

pub fn Init(target_fps: u32) Time {
    const fixed_dt: f64 = 1.0 / @as(f64, @floatFromInt(target_fps));
    const freq = sdl.SDL_GetPerformanceFrequency();
    const prev = sdl.SDL_GetPerformanceCounter();

    return Time{
        .fixed_dt = fixed_dt,
        ._freq = freq,
        ._accumulator = 0,
        ._prev = prev,
    };
}

pub fn Update(self: *Time) void {
    const now = sdl.SDL_GetPerformanceCounter();
    //     const frameTime = now - self._prev;
    const frameTime = @as(f64, @floatFromInt(now - self._prev)) / @as(f64, @floatFromInt(self._freq));

    self._prev = now;
    self._accumulator += frameTime;
}

pub fn ShouldTick(self: Time) bool {
    return self._accumulator >= self.fixed_dt;
}

pub fn ConsumeTick(self: *Time) void {
    self._accumulator -= self.fixed_dt;
}
