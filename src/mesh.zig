pub const Mesh = @This();

const std = @import("std");
const Vector3 = @import("vector.zig").Vector3;
const Vertex = @import("vertex.zig");

vertices: std.ArrayList(Vertex),
rotation: Vector3,
scale: Vector3,
translation: Vector3,

pub fn init(vertices: std.ArrayList(Vertex)) Mesh {
    const rotation: Vector3 = .{ .x = 0, .y = 0, .z = 0 };
    const scale: Vector3 = .{ .x = 1.0, .y = 1.0, .z = 1.0 };
    const translation: Vector3 = .{ .x = 0, .y = 0, .z = 0 };

    return .{
        .vertices = vertices,
        .rotation = rotation,
        .scale = scale,
        .translation = translation,
    };
}
