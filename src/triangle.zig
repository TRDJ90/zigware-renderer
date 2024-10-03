const Color = @import("color.zig").Color;
const Vertex = @import("vertex.zig").Vertex;
const Vector = @import("vector.zig");
const Vector2 = Vector.Vector2;
const Vector3 = Vector.Vector3;
const Vector4 = Vector.Vector4;

pub const Face = struct {
    a: u16,
    b: u16,
    c: u16,
    color: Color,
};

pub const Triangle = struct {
    vertices: [3]Vertex,
    color: Color,
};

pub fn barycentricWeights(a: *const Vector2, b: *const Vector2, c: *const Vector2, p: *const Vector2) Vector3 {
    const ac: Vector2 = Vector.subVec2(c, a);
    const ab: Vector2 = Vector.subVec2(b, a);
    const ap: Vector2 = Vector.subVec2(p, a);
    const pc: Vector2 = Vector.subVec2(c, p);
    const pb: Vector2 = Vector.subVec2(b, p);

    const area_parallelogram_abc: f32 = (ac.x * ab.y - ac.y * ab.x);

    const alpha = (pc.x * pb.y - pc.y * pb.x) / area_parallelogram_abc;
    const beta = (ac.x * ap.y - ac.y * ap.x) / area_parallelogram_abc;

    const gamma = 1.0 - alpha - beta;

    return .{ .x = alpha, .y = beta, .z = gamma };
}
