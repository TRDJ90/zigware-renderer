const Vector2 = @import("vector.zig").Vector2;

pub const Face = struct {
    a: u16,
    b: u16,
    c: u16,
};

pub const Triangle = struct {
    points: [3]Vector2,
};
