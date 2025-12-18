const std = @import("std");

const int2 = @import("int2.zig");
const E_SHAPE = @import("E_SHAPE.zig").E_SHAPE;

const assert = std.debug.assert;

const Shape = @This();

name: E_SHAPE,
points: [16]int2,
pointlen: usize,

pub fn Init(name: E_SHAPE, points: []const int2) Shape {
    assert(points.len <= 16);

    var ret = Shape{
        .name = name,
        .points = undefined,
        .pointlen = points.len,
    };

    @memcpy(ret.points[0..points.len], points);

    return ret;
}

pub fn format(self: *const Shape, writer: *std.Io.Writer) std.Io.Writer.Error!void {
    try writer.print("{s}[", .{@tagName(self.name)});
    for (self.points[0..self.pointlen], 0..) |point, index| {
        try writer.print("{f}", .{point});
        if (index != self.pointlen - 1) {
            try writer.print(", ", .{});
        }
    }
    try writer.print("]", .{});
}

const Iterator = struct {
    slice: []const int2,
    pub fn next(self: *@This()) ?int2 {
        if (self.slice.len == 0) {
            return null;
        }
        const item = self.slice[0];
        self.slice = self.slice[1..];
        return item;
    }
};

pub fn iterate(self: *const Shape) Iterator {
    return Iterator{ .slice = self.points[0..self.pointlen] };
}

pub fn Clone(self: *const Shape) Shape {
    return Shape.Init(self.name, self.points[0..self.pointlen]);
}

pub fn _InternalRotate(shape: *const Shape) Shape {
    var ret = Shape{
        .name = shape.name,
        .points = undefined,
        .pointlen = shape.pointlen,
    };

    for (shape.points[0..shape.pointlen], 0..) |*p, i| {
        ret.points[i] = p.rotate();
    }

    return ret;
}

pub fn Add(self: *const Shape, addp: int2) Shape {
    var ret = Shape{
        .name = self.name,
        .points = undefined,
        .pointlen = self.pointlen,
    };

    for (self.points[0..self.pointlen], 0..) |*p, i| {
        ret.points[i] = p.add(addp);
    }

    return ret;
}
