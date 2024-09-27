const std = @import("std");
const Vector3 = @import("vector.zig").Vector3;
const Face = @import("triangl.zig").Face;

pub const Mesh = struct {
    vertices: std.ArrayList(Vector3),
    faces: std.ArrayList(Face),

    pub fn init(vertices: std.ArrayList(Vector3), faces: std.ArrayList(Face)) Mesh {
        return .{
            .vertices = vertices,
            .faces = faces,
        };
    }
};
