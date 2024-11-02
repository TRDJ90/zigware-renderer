const std = @import("std");
const sin = std.math.sin;
const cos = std.math.cos;
const tan = std.math.tan;

const Vector = @import("vector.zig");
const Vector3 = Vector.Vector3;
const Vector4 = Vector.Vector4;

pub const Matrix4x4 = struct {
    values: [4][4]f32,
};

pub fn identityMat4x4() Matrix4x4 {
    return .{
        .values = [4][4]f32{
            [_]f32{ 1, 0, 0, 0 },
            [_]f32{ 0, 1, 0, 0 },
            [_]f32{ 0, 0, 1, 0 },
            [_]f32{ 0, 0, 0, 1 },
        },
    };
}

pub fn scaleMat4x4(x: f32, y: f32, z: f32) Matrix4x4 {
    return .{
        .values = [4][4]f32{
            [_]f32{ x, 0, 0, 0 },
            [_]f32{ 0, y, 0, 0 },
            [_]f32{ 0, 0, z, 0 },
            [_]f32{ 0, 0, 0, 1 },
        },
    };
}

pub fn translateMat4x4(x: f32, y: f32, z: f32) Matrix4x4 {
    return .{
        .values = [4][4]f32{
            [_]f32{ 1, 0, 0, x },
            [_]f32{ 0, 1, 0, y },
            [_]f32{ 0, 0, 1, z },
            [_]f32{ 0, 0, 0, 1 },
        },
    };
}

pub fn rotationMat4x4Z(z: f32) Matrix4x4 {
    return .{
        .values = [4][4]f32{
            [_]f32{ cos(z), -sin(z), 0, 0 },
            [_]f32{ sin(z), cos(z), 0, 0 },
            [_]f32{ 0, 0, 1, 0 },
            [_]f32{ 0, 0, 0, 1 },
        },
    };
}
pub fn rotationMat4x4X(x: f32) Matrix4x4 {
    return .{
        .values = [4][4]f32{
            [_]f32{ 1, 0, 0, 0 },
            [_]f32{ 0, cos(x), -sin(x), 0 },
            [_]f32{ 0, sin(x), cos(x), 0 },
            [_]f32{ 0, 0, 0, 1 },
        },
    };
}
pub fn rotationMat4x4Y(y: f32) Matrix4x4 {
    return .{
        .values = [4][4]f32{
            [_]f32{ cos(y), 0, sin(y), 0 },
            [_]f32{ 0, 1, 0, 0 },
            [_]f32{ -sin(y), 0, cos(y), 0 },
            [_]f32{ 0, 0, 0, 1 },
        },
    };
}

pub fn rotationMat4x4(x: f32, y: f32, z: f32) Matrix4x4 {
    return .{
        .values = [4][4]f32{
            [_]f32{ 1, 0, 0, x },
            [_]f32{ 0, 1, 0, y },
            [_]f32{ 0, 0, 1, z },
            [_]f32{ 0, 0, 0, 1 },
        },
    };
}

pub fn mat4MulVec4(matrix: *const Matrix4x4, vector: *const Vector4) Vector4 {
    var v: Vector4 = undefined;
    v.x = matrix.values[0][0] * vector.x + matrix.values[0][1] * vector.y + matrix.values[0][2] * vector.z + matrix.values[0][3] * vector.w;
    v.y = matrix.values[1][0] * vector.x + matrix.values[1][1] * vector.y + matrix.values[1][2] * vector.z + matrix.values[1][3] * vector.w;
    v.z = matrix.values[2][0] * vector.x + matrix.values[2][1] * vector.y + matrix.values[2][2] * vector.z + matrix.values[2][3] * vector.w;
    v.w = matrix.values[3][0] * vector.x + matrix.values[3][1] * vector.y + matrix.values[3][2] * vector.z + matrix.values[3][3] * vector.w;

    return v;
}

pub fn mat4MulMat4(a: *const Matrix4x4, b: *const Matrix4x4) Matrix4x4 {
    var result: Matrix4x4 = undefined;

    for (0..4) |i| {
        for (0..4) |j| {
            result.values[i][j] =
                a.values[i][0] * b.values[0][j] +
                a.values[i][1] * b.values[1][j] +
                a.values[i][2] * b.values[2][j] +
                a.values[i][3] * b.values[3][j];
        }
    }
    return result;
}

pub fn makePerspectiveMat4(fov: f32, aspect: f32, z_near: f32, z_far: f32) Matrix4x4 {
    const tan_half_fov = tan(fov / 2);
    const z_range = z_near - z_far;

    var matrix: Matrix4x4 = undefined;

    matrix.values[0][0] = 1.0 / (tan_half_fov * aspect);
    matrix.values[1][1] = 1.0 / tan_half_fov;
    matrix.values[2][2] = (-z_near - z_far) / z_range;
    matrix.values[2][3] = 2 * z_far * z_near / z_range;
    matrix.values[3][2] = 1.0;

    return matrix;
}

pub fn makeScreenspaceTransform(half_width: f32, half_height: f32) Matrix4x4 {
    var matrix: Matrix4x4 = undefined;

    matrix.values[0][0] = half_width;
    matrix.values[0][3] = half_width - 0.5;

    matrix.values[1][1] = -half_height;
    matrix.values[1][3] = half_height - 0.5;

    matrix.values[2][2] = 1.0;
    matrix.values[3][3] = 1.0;

    return matrix;
}

pub fn LookAtMat4(eye: Vector3, target: Vector3, up: Vector3) Matrix4x4 {
    var z: Vector3 = Vector.subVec3(&target, &eye);
    Vector.normalizeVec3(&z);

    var x: Vector3 = Vector.crossVec3(&up, &z);
    Vector.normalizeVec3(&x);

    const y: Vector3 = Vector.crossVec3(&z, &x);

    return .{
        .values = [4][4]f32{
            [4]f32{ x.x, x.y, x.z, -1.0 * Vector.dotVec3(&x, &eye) },
            [4]f32{ y.x, y.y, y.z, -1.0 * Vector.dotVec3(&y, &eye) },
            [4]f32{ z.x, z.y, z.z, -1.0 * Vector.dotVec3(&z, &eye) },
            [4]f32{ 0, 0, 0, 1.0 },
        },
    };
}

pub fn mat4ProjVec42(matrix: Matrix4x4, vector: Vector4) Vector4 {
    var result: Vector4 = mat4MulVec4(&matrix, &vector);

    if (result.w != 0.0) {
        result.x /= result.w;
        result.y /= result.w;
        result.z /= result.w;
    }

    return result;
}
