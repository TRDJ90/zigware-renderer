pub const Renderer = @This();

const std = @import("std");
const rl = @import("raylib");

const Display = @import("display.zig");
const Rasterizer = @import("rasterizer.zig");
const Camera = @import("camera.zig");
const Color = @import("color.zig").Color;
const Vertex = @import("vertex.zig");
const Face = @import("triangle.zig");
const Triangle = @import("triangle.zig");
const Clipping = @import("clipping.zig");
const Mesh = @import("mesh.zig");
const Model = @import("model.zig");

const Vector = @import("vector.zig");
const Matrix = @import("matrix.zig");
const Vector2 = Vector.Vector2;
const Vector3 = Vector.Vector3;
const Vector4 = Vector.Vector4;
const Matrix4x4 = Matrix.Matrix4x4;

width: u16,
height: u16,
display: Display,
rasterizer: Rasterizer,
triangle_list: std.ArrayList(Triangle),
proj_mat: Matrix4x4,

pub fn init(allocator: std.mem.Allocator, width: u16, height: u16) !Renderer {
    var display = try Display.init(allocator, width, height);
    const rasterizer = Rasterizer.init(&display, width, height);
    const triangle_list = std.ArrayList(Triangle).init(allocator);

    const fov: f32 = std.math.pi / 3.0;
    const aspect: f32 = @as(f32, @floatFromInt(width)) / @as(f32, @floatFromInt(height));
    const znear: f32 = 0.1;
    const zfar: f32 = 100.0;
    const proj_mat = Matrix.makePerspectiveMat4(fov, aspect, znear, zfar);

    return .{
        .display = display,
        .rasterizer = rasterizer,
        .triangle_list = triangle_list,
        .proj_mat = proj_mat,
        .width = width,
        .height = height,
    };
}

pub fn render(
    self: *Renderer,
    camera: *Camera,
    models: *std.ArrayList(Model),
) !void {
    rl.beginDrawing();
    rl.clearBackground(rl.Color.sky_blue);

    const delta_time = rl.getFrameTime();

    for (models.items) |*model| {
        var mesh = model.mesh;
        mesh.rotation.y += 0.5 * delta_time;
        mesh.rotation.x += 0.5 * delta_time;
        mesh.rotation.z += 0.5 * delta_time;
        mesh.translation.z = 0.0;

        const scale_mat: Matrix4x4 = Matrix.scaleMat4x4(mesh.scale.x, mesh.scale.y, mesh.scale.z);
        const translation_mat: Matrix4x4 = Matrix.translateMat4x4(mesh.translation.x, mesh.translation.y, mesh.translation.z);
        const rotation_mat_x: Matrix4x4 = Matrix.rotationMat4x4X(mesh.rotation.x);
        const rotation_mat_y: Matrix4x4 = Matrix.rotationMat4x4Y(mesh.rotation.y);
        const rotation_mat_z: Matrix4x4 = Matrix.rotationMat4x4Z(mesh.rotation.z);

        const view_matrix: Matrix4x4 = camera.lookAtMatrix();

        var world_matrix = Matrix.identityMat4x4();
        world_matrix = Matrix.mat4MulMat4(&scale_mat, &world_matrix);
        world_matrix = Matrix.mat4MulMat4(&rotation_mat_z, &world_matrix);
        world_matrix = Matrix.mat4MulMat4(&rotation_mat_y, &world_matrix);
        world_matrix = Matrix.mat4MulMat4(&rotation_mat_x, &world_matrix);
        world_matrix = Matrix.mat4MulMat4(&translation_mat, &world_matrix);

        const screenspace_matrix = Matrix.makeScreenspaceTransform(
            @as(f32, @floatFromInt(self.width)) / 2,
            @as(f32, @floatFromInt(self.height)) / 2,
        );

        // Note: Process model's triangles.
        var vertex_index: usize = 0;
        while (vertex_index < mesh.vertices.items.len - 2) : (vertex_index += 3) {
            const vertex_a: Vertex = mesh.vertices.items[vertex_index];
            const vertex_b: Vertex = mesh.vertices.items[vertex_index + 1];
            const vertex_c: Vertex = mesh.vertices.items[vertex_index + 2];

            var triangle: Triangle = Triangle.init(vertex_a, vertex_b, vertex_c);

            // Go from model to world space
            for (0..triangle.vertices.len) |i| {
                var world_view_position: Vector4 = triangle.vertices[i].position;

                world_view_position = Matrix.mat4MulVec4(&world_matrix, &world_view_position);
                world_view_position = Matrix.mat4MulVec4(&view_matrix, &world_view_position);

                triangle.vertices[i].position = world_view_position;
            }

            // Do backface culling
            if (backFaceCulling(&triangle)) {
                continue;
            }

            // Go from world to ndc space
            for (0..triangle.vertices.len) |i| {
                var vertex_ptr = &triangle.vertices[i];
                vertex_ptr.*.position = Matrix.mat4MulVec4(&self.proj_mat, &vertex_ptr.position);
                vertex_ptr.*.position = Matrix.mat4MulVec4(&screenspace_matrix, &vertex_ptr.position);

                // Do the perspective divide.
                if (vertex_ptr.position.w != 0) {
                    vertex_ptr.position.x /= vertex_ptr.position.w;
                    vertex_ptr.position.y /= vertex_ptr.position.w;
                    vertex_ptr.position.z /= vertex_ptr.position.w;
                }
            }

            try self.triangle_list.append(triangle);
        }
        // Render triangles
        for (self.triangle_list.items) |triangle| {
            Rasterizer.drawTriangle(&self.display, &triangle, &models.items[0].texture);
            //Rasterizer.drawTriangleLines(&self.display, &triangle, Color.black);
        }
    }

    self.display.present();

    rl.drawFPS(10, 10);
    rl.drawCircle(self.width / 2, self.height / 2, 3, rl.Color.black);
    rl.endDrawing();

    self.display.clearColorBuffer(Color.light_gray);
    self.display.clearDepthBuffer();
    self.triangle_list.clearRetainingCapacity();
}

fn backFaceCulling(triangle: *Triangle) bool {
    const vector_1 = Vector.vec4ToVec3(&triangle.vertices[0].position);
    const vector_2 = Vector.vec4ToVec3(&triangle.vertices[1].position);
    const vector_3 = Vector.vec4ToVec3(&triangle.vertices[2].position);

    var vector_12 = Vector.subVec3(&vector_2, &vector_1);
    var vector_13 = Vector.subVec3(&vector_3, &vector_1);

    Vector.normalizeVec3(&vector_12);
    Vector.normalizeVec3(&vector_13);

    var normal = Vector.crossVec3(&vector_12, &vector_13);
    Vector.normalizeVec3(&normal);

    const origin: Vector3 = .{ .x = 0, .y = 0, .z = 0 };
    const camera_ray = Vector.subVec3(&origin, &vector_1);
    const dot_normal_camera: f32 = Vector.dotVec3(&normal, &camera_ray);

    return dot_normal_camera < 0;
}
