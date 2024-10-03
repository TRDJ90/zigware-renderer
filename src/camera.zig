const Vector3 = @import("vector.zig").Vector3;

pub const LookAtCamera = struct {
    position: Vector3,
    target: Vector3,
};

pub const FpsCamera = struct {
    position: Vector3,
    direction: Vector3,
    forward_velocity: Vector3,
    yaw: f32 = 0,
    pitch: f32 = 0,
};
