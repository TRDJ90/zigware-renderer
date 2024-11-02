pub const Camera = @This();

const Vector = @import("vector.zig");
const Vector3 = Vector.Vector3;
const Vector4 = Vector.Vector4;
const Matrix = @import("matrix.zig");
const Matrix4x4 = Matrix.Matrix4x4;

position: Vector3,
target: Vector3,
direction: Vector3,
yaw: f32 = 0,
pitch: f32 = 0,

pub fn init(position: Vector3, direction: Vector3, target: Vector3) Camera {
    return .{
        .position = position,
        .direction = direction,
        .target = target,
        .yaw = 0.0,
        .pitch = 0.0,
    };
}

pub fn updateCamera(self: *Camera, movement: *Vector3, yaw: f32, pitch: f32) void {
    // Update camera position, yaw and pitch
    self.position.x += movement.x;
    self.position.y += movement.y;
    self.position.z += movement.z;

    self.yaw += yaw;
    self.pitch += pitch;
}

pub fn lookAtMatrix(self: *Camera) Matrix4x4 {
    const up: Vector3 = .{ .x = 0, .y = 1, .z = 0 };
    const target: Vector4 = .{ .x = 0, .y = 0, .z = 1, .w = 0 };
    var camera_yaw_rotation = Matrix.rotationMat4x4Y(self.yaw);
    var camera_pitch_rotation = Matrix.rotationMat4x4Y(self.pitch);

    var camera_rotation = Matrix.identityMat4x4();
    camera_rotation = Matrix.mat4MulMat4(&camera_pitch_rotation, &camera_rotation);
    camera_rotation = Matrix.mat4MulMat4(&camera_yaw_rotation, &camera_rotation);

    const camera_direction = Matrix.mat4MulVec4(&camera_rotation, &target);

    self.direction = Vector.vec4ToVec3(&camera_direction);
    self.target = Vector.addVec3(&self.position, &self.direction);

    return Matrix.LookAtMat4(
        self.position,
        self.target,
        up,
    );
}
