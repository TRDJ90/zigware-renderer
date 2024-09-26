const math = @import("std").math;

pub const Vector2 = struct {
    x: f32,
    y: f32,

    pub fn init(x: f32, y: f32) Vector2 {
        return .{ .x = x, .y = y };
    }
};

pub const Vector3 = struct {
    x: f32,
    y: f32,
    z: f32,

    pub fn init(x: f32, y: f32, z: f32) Vector3 {
        return .{ .x = x, .y = y, .z = z };
    }
};

pub fn vec3RotateX(vector: Vector3, angle: f32) Vector3 {
    return .{
        .x = vector.x,
        .y = vector.y * math.cos(angle) - vector.z * math.sin(angle),
        .z = vector.y * math.sin(angle) + vector.z * math.cos(angle),
    };
}

pub fn vec3RotateY(vector: Vector3, angle: f32) Vector3 {
    return .{
        .x = vector.x * math.cos(angle) - vector.z * math.sin(angle),
        .y = vector.y,
        .z = vector.x * math.sin(angle) + vector.z * math.cos(angle),
    };
}

pub fn vec3RotateZ(vector: Vector3, angle: f32) Vector3 {
    return .{
        .x = vector.x * math.cos(angle) - vector.y * math.sin(angle),
        .y = vector.x * math.sin(angle) + vector.y * math.cos(angle),
        .z = vector.z,
    };
}
