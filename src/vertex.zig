pub const Vertex = @This();

const Color = @import("color.zig").Color;
const TextureCoords = @import("texturecoords.zig");
const Vector = @import("vector.zig");
const Vector3 = Vector.Vector3;
const Vector4 = Vector.Vector4;

position: Vector4 = .{ .x = 0, .y = 0, .z = 0, .w = 1 },
normal: Vector3 = .{ .x = 0, .y = 0, .z = 0 },
color: Color = .{ .a = 0, .r = 0, .g = 0, .b = 0 },
tex_coord: TextureCoords = .{ .u = 0, .v = 0 },
