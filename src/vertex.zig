const Color = @import("color.zig").Color;
const Tex2Coord = @import("texture.zig").Tex2Coord;
const Vector = @import("vector.zig");
const Vector3 = Vector.Vector3;
const Vector4 = Vector.Vector4;

pub const Vertex = struct {
    position: Vector4 = .{ .x = 0, .y = 0, .z = 0, .w = 1 },
    normal: Vector3 = .{ .x = 0, .y = 0, .z = 0 },
    color: Color = .{ .a = 0, .r = 0, .g = 0, .b = 0 },
    tex_coord: Tex2Coord = .{ .u = 0, .v = 0 },
};
