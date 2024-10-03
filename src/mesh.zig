const std = @import("std");
const Vector3 = @import("vector.zig").Vector3;
const Face = @import("triangle.zig").Face;
const Color = @import("color.zig").Color;
const Vertex = @import("vertex.zig").Vertex;

pub const Mesh = struct {
    vertices: std.ArrayList(Vertex),
    faces: std.ArrayList(Face),
    rotation: Vector3,
    scale: Vector3,
    translation: Vector3,

    pub fn init(vertices: std.ArrayList(Vector3), faces: std.ArrayList(Face)) Mesh {
        const rotation: Vector3 = .{ .x = 0, .y = 0, .z = 0 };
        const scale: Vector3 = .{ .x = 1.0, .y = 1.0, .z = 1.0 };
        const translation: Vector3 = .{ .x = 0, .y = 0, .z = 0 };

        return .{
            .vertices = vertices,
            .faces = faces,
            .rotation = rotation,
            .scale = scale,
            .translation = translation,
        };
    }
};

pub const cube_vertices = [_]Vertex{
    // zig fmt: off
    .{.position = .{ .x = -1, .y = -1, .z = -1, .w = 1}, .color = Color.red }, // 1
    .{.position = .{ .x = -1, .y =  1, .z = -1, .w = 1}, .color = Color.red }, // 2
    .{.position = .{ .x =  1, .y =  1, .z = -1, .w = 1}, .color = Color.red }, // 3
    .{.position = .{ .x =  1, .y = -1, .z = -1, .w = 1}, .color = Color.red }, // 4
    .{.position = .{ .x =  1, .y =  1, .z =  1, .w = 1}, .color = Color.red }, // 5
    .{.position = .{ .x =  1, .y = -1, .z =  1, .w = 1}, .color = Color.red }, // 6
    .{.position = .{ .x = -1, .y =  1, .z =  1, .w = 1}, .color = Color.red }, // 7
    .{.position = .{ .x = -1, .y = -1, .z =  1, .w = 1}, .color = Color.red }, // 8
    // zig fmt: on
};
pub const cube_faces = [_]Face{
    // front
    .{ .a = 0, .b = 1, .c = 2, .color = Color.red },
    .{ .a = 0, .b = 2, .c = 3, .color = Color.red },
    // right
    .{ .a = 3, .b = 2, .c = 4, .color = Color.yellow },
    .{ .a = 3, .b = 4, .c = 5, .color = Color.yellow },
    // back
    .{ .a = 5, .b = 4, .c = 6, .color = Color.blue },
    .{ .a = 5, .b = 6, .c = 7, .color = Color.blue },
    // left
    .{ .a = 7, .b = 6, .c = 1, .color = Color.green },
    .{ .a = 7, .b = 1, .c = 0, .color = Color.green },
    // top
    .{ .a = 1, .b = 6, .c = 4, .color = Color.light_gray },
    .{ .a = 1, .b = 4, .c = 2, .color = Color.light_gray },
    // bottom
    .{ .a = 5, .b = 7, .c = 0, .color = Color.dark_gray },
    .{ .a = 5, .b = 0, .c = 3, .color = Color.dark_gray },
};

pub fn loadCubeMeshData(allocator: std.mem.Allocator) !Mesh {
    var cube: Mesh = undefined;
    
    cube.rotation = .{ .x = 0, .y = 0, .z = 0 };
    cube.scale = .{ .x = 1.0, .y = 1.0, .z = 1.0 };
    cube.translation = .{ .x = 0, .y = 0, .z = 0 };

    cube.vertices = std.ArrayList(Vertex).init(allocator);
    cube.faces = std.ArrayList(Face).init(allocator);

    for(cube_vertices) |vertex| {
        try cube.vertices.append(vertex);
    }

    for(cube_faces) |face| {
        try cube.faces.append(face);
    }

    return cube; 
}

pub fn loadTriangleMeshData(allocator: std.mem.Allocator) !Mesh {
    var tri: Mesh = undefined;
    
    tri.rotation = .{ .x = 0, .y = 0, .z = 0 };
    tri.scale = .{ .x = 1.0, .y = 1.0, .z = 1.0 };
    tri.translation = .{ .x = 0, .y = 0, .z = 0 };

    tri.vertices = std.ArrayList(Vertex).init(allocator);
    tri.faces = std.ArrayList(Face).init(allocator);

    try tri.vertices.append(.{.position = .{ .x = 1.5, .y = 2.5, .z = 3, .w = 1},   .color = Color.red });
    try tri.vertices.append(.{.position = .{ .x = 2.5, .y = -2.0, .z = 3, .w = 1},  .color = Color.blue });
    try tri.vertices.append(.{.position = .{ .x = -2.0, .y = -2.5, .z = 3, .w = 1}, .color = Color.green });
    try tri.faces.append(.{.a = 0, .b = 1, .c = 2, .color = Color.red});

    return tri; 
}
