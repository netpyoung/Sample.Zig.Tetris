const std = @import("std");
const assert = std.debug.assert;

const int2 = @import("int2.zig");
const Shape = @import("Shape.zig");
const E_SHAPE = @import("E_SHAPE.zig").E_SHAPE;

const Table = @This();

width: usize,
height: usize,
_arr: []i32,
_buffForIndex: []usize,

pub fn Init(allocator: std.mem.Allocator, width: usize, height: usize) Table {
    const size: usize = @intCast(width * height);
    const arr = allocator.alloc(i32, size) catch unreachable;
    @memset(arr[0..arr.len], 0);

    const fulled_rows = allocator.alloc(usize, height) catch unreachable;

    return Table{
        .width = width,
        .height = height,
        ._arr = arr,
        ._buffForIndex = fulled_rows,
    };
}

pub fn Deinit(self: *Table, allocator: std.mem.Allocator) void {
    allocator.free(self._arr);
    allocator.free(self._buffForIndex);
}

pub fn format(self: *const Table, writer: *std.Io.Writer) std.Io.Writer.Error!void {
    for (0..self.height) |y| {
        for (0..self.width) |x| {
            const idx = x + y * self.width;
            const v = self._arr[idx];
            const e: E_SHAPE = @enumFromInt(v);

            if (e == E_SHAPE.NONE) {
                try writer.print(".", .{});
            } else {
                try writer.print("{s}", .{@tagName(e)});
            }
        }
        try writer.print("\n", .{});
    }
}

pub fn GetValue(self: *const Table, x: usize, y: usize) E_SHAPE {
    assert(0 <= x and x < self.width);
    assert(0 <= y and y < self.height);

    const idx = x + y * self.width;
    const curr = self._arr[idx];
    const e: E_SHAPE = @enumFromInt(curr);
    return e;
}

pub fn ShapeIntoTable(self: *Table, p: int2, shape: *const Shape) void {
    const v: i32 = @intCast(@intFromEnum(shape.name));
    for (shape.points[0..shape.pointlen]) |shapep| {
        const x = p.x + shapep.x;
        const y = p.y + shapep.y;
        assert(x >= 0);
        assert(y >= 0);
        assert(x < self.width);
        assert(y < self.height);

        const w: i32 = @intCast(self.width);
        const idx: usize = @intCast(x + y * w);
        self._arr[idx] = v;
    }
}

pub fn IsCollision(self: *const Table, shape: *const Shape) bool {
    for (shape.points[0..shape.pointlen]) |p| {
        const x = p.x;
        const y = p.y;

        if (x < 0 or self.width <= x) {
            return true;
        }
        if (y < 0 or self.height <= y) {
            return true;
        }

        const w: i32 = @intCast(self.width);
        const idx: usize = @intCast(x + y * w);
        const v = self._arr[idx];
        const e: E_SHAPE = @enumFromInt(v);
        if (e != E_SHAPE.NONE) {
            return true;
        }
    }

    return false;
}

pub fn RemoveFulledRows(self: *Table) usize {
    const fulledIndexes = self._FindFulledRowIndexes();
    if (fulledIndexes.len == 0) {
        return 0;
    }

    const w = self.width;

    // compact
    for (fulledIndexes) |fulledIndex| {
        if (fulledIndex == 0) {
            @memset(self._arr[0..w], 0);
            continue;
        }

        var y: usize = fulledIndex;
        while (y > 0) : (y -= 1) {
            const idx_0 = y * w;
            const idx_1 = (y - 1) * w;
            @memcpy(self._arr[idx_0..(idx_0 + w)], self._arr[idx_1..(idx_1 + w)]);
        }
    }
    return fulledIndexes.len;
}

// ===============================================================================
// ===============================================================================

fn _FindFulledRowIndexes(self: *const Table) []usize {
    const w = self.width;

    var count: usize = 0;
    for (0..self.height) |y| {
        const idx = y * self.width;
        const indexOf = std.mem.indexOfScalar(i32, self._arr[idx..(idx + w)], 0);
        if (indexOf == null) {
            self._buffForIndex[count] = y;
            count += 1;
        }
    }

    return self._buffForIndex[0..count];
}

fn _IsRowFull(fulled_rows: []const usize, row: usize) bool {
    return std.mem.indexOfScalar(usize, fulled_rows, row) != null;
}
