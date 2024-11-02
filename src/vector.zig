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

pub const Vector4 = struct {
    x: f32,
    y: f32,
    z: f32,
    w: f32,

    pub fn init(x: f32, y: f32, z: f32, w: f32) Vector4 {
        return .{ .x = x, .y = y, .z = z, .w = w };
    }
};

// Vector2 functions
pub fn lengthVec2(vector: Vector2) f32 {
    return math.sqrt(vector.x * vector.x + vector.y * vector.y);
}

pub fn addVec2(a: *const Vector2, b: *const Vector2) Vector2 {
    return .{
        .x = a.x + b.x,
        .y = a.y + b.y,
    };
}

pub fn subVec2(a: *const Vector2, b: *const Vector2) Vector2 {
    return .{
        .x = a.x - b.x,
        .y = a.y - b.y,
    };
}

pub fn mulVec2(scalar: f32, vector: *const Vector2) Vector2 {
    return .{
        .x = vector.x * scalar,
        .y = vector.y * scalar,
    };
}

pub fn divVec2(scalar: f32, vector: *const Vector2) Vector2 {
    return .{
        .x = vector.x / scalar,
        .y = vector.y / scalar,
    };
}

pub fn normalizeVec2(self: *Vector2) void {
    const length: f32 = math.sqrt(self.x * self.x + self.y * self.y);
    self.x /= length;
    self.y /= length;
}

// Vector3 functions
pub fn lengthVec3(vector: *const Vector3) f32 {
    return math.sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z);
}

pub fn addVec3(a: *const Vector3, b: *const Vector3) Vector3 {
    return .{
        .x = a.x + b.x,
        .y = a.y + b.y,
        .z = a.z + b.z,
    };
}

pub fn subVec3(a: *const Vector3, b: *const Vector3) Vector3 {
    return .{
        .x = a.x - b.x,
        .y = a.y - b.y,
        .z = a.z - b.z,
    };
}

pub fn mulVec3(scalar: f32, vector: *const Vector3) Vector3 {
    return .{
        .x = vector.x * scalar,
        .y = vector.y * scalar,
        .z = vector.z * scalar,
    };
}

pub fn divVec3(scalar: f32, vector: *const Vector3) Vector3 {
    return .{
        .x = vector.x / scalar,
        .y = vector.y / scalar,
        .z = vector.z / scalar,
    };
}

pub fn vec3RotateX(vector: *const Vector3, angle: f32) Vector3 {
    return .{
        .x = vector.x,
        .y = vector.y * math.cos(angle) - vector.z * math.sin(angle),
        .z = vector.y * math.sin(angle) + vector.z * math.cos(angle),
    };
}

pub fn vec3RotateY(vector: *const Vector3, angle: f32) Vector3 {
    return .{
        .x = vector.x * math.cos(angle) - vector.z * math.sin(angle),
        .y = vector.y,
        .z = vector.x * math.sin(angle) + vector.z * math.cos(angle),
    };
}

pub fn vec3RotateZ(vector: *const Vector3, angle: f32) Vector3 {
    return .{
        .x = vector.x * math.cos(angle) - vector.y * math.sin(angle),
        .y = vector.x * math.sin(angle) + vector.y * math.cos(angle),
        .z = vector.z,
    };
}

pub fn crossVec3(a: *const Vector3, b: *const Vector3) Vector3 {
    return .{
        .x = a.y * b.z - a.z * b.y,
        .y = a.z * b.x - a.x * b.z,
        .z = a.x * b.y - a.y * b.x,
    };
}

pub fn dotVec3(a: *const Vector3, b: *const Vector3) f32 {
    return (a.x * b.x) + (a.y * b.y) + (a.z * b.z);
}

pub fn dotVec3FromVec4(a: *const Vector4, b: *const Vector4) f32 {
    return (a.x * b.x) + (a.y * b.y) + (a.z * b.z);
}

pub fn normalizeVec3(self: *Vector3) void {
    const length: f32 = math.sqrt(self.x * self.x + self.y * self.y + self.z * self.z);
    self.x /= length;
    self.y /= length;
    self.z /= length;
}

// Convert functions
pub fn vec3ToVec4(vector: *const Vector3) Vector4 {
    return .{
        .x = vector.x,
        .y = vector.y,
        .z = vector.z,
        .w = 1,
    };
}

pub fn vec4ToVec2(vector: *const Vector4) Vector2 {
    return .{
        .x = vector.x,
        .y = vector.y,
    };
}

pub fn vec4ToVec3(vector: *const Vector4) Vector3 {
    return .{
        .x = vector.x,
        .y = vector.y,
        .z = vector.z,
    };
}
