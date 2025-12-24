const Timer = @This();

_accSec: f64,
_targetSec: f64,

pub fn Init(targetSec: f64) Timer {
    return Timer{
        ._accSec = 0,
        ._targetSec = targetSec,
    };
}

pub fn Tick(self: *Timer, dt: f64) bool {
    self._accSec += dt;
    if (self._accSec < self._targetSec) {
        return false;
    }
    self._accSec = 0;
    return true;
}

pub fn IsTicked(self: *const Timer) bool {
    return self._accSec == 0;
}
