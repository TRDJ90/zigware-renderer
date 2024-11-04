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
const RenderDiagnostics = @import("render_diagnostics.zig");

const Vector = @import("vector.zig");
const Matrix = @import("matrix.zig");
const Vector2 = Vector.Vector2;
const Vector3 = Vector.Vector3;
const Vector4 = Vector.Vector4;
const Matrix4x4 = Matrix.Matrix4x4;

pub const RenderMode = enum {
    rasterized,
    wireframe,
    points,
};

width: u16,
height: u16,
display: Display,
rasterizer: Rasterizer,
triangle_list: std.ArrayList(Triangle),
proj_mat: Matrix4x4,
render_mode: RenderMode,

var culled_triangles: u32 = 0;
var total_triangles: u32 = 0;
var rendered_triangles: u32 = 0;
var vertex_time_ms: i64 = 0.0;
var pixel_time_ms: i64 = 0.0;
var render_time_ns: i64 = 0.0;

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
        .render_mode = RenderMode.rasterized,
    };
}

pub fn setRenderMode(self: *Renderer, mode: RenderMode) void {
    self.render_mode = mode;
}

pub fn render(
    self: *Renderer,
    camera: *Camera,
    models: *std.ArrayList(Model),
) !void {
    const delta_time = rl.getFrameTime();
    const start_time = std.time.milliTimestamp();

    for (models.items) |*model| {
        var mesh_ptr = &model.mesh;
        mesh_ptr.rotation.y += 0.5 * delta_time;
        mesh_ptr.translation.z = 3.0;

        const scale_mat: Matrix4x4 = Matrix.scaleMat4x4(mesh_ptr.scale.x, mesh_ptr.scale.y, mesh_ptr.scale.z);
        const translation_mat: Matrix4x4 = Matrix.translateMat4x4(mesh_ptr.translation.x, mesh_ptr.translation.y, mesh_ptr.translation.z);
        const rotation_mat_x: Matrix4x4 = Matrix.rotationMat4x4X(mesh_ptr.rotation.x);
        const rotation_mat_y: Matrix4x4 = Matrix.rotationMat4x4Y(mesh_ptr.rotation.y);
        const rotation_mat_z: Matrix4x4 = Matrix.rotationMat4x4Z(mesh_ptr.rotation.z);

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
        while (vertex_index < mesh_ptr.vertices.items.len - 2) : (vertex_index += 3) {
            var triangle = [3]Vector4{
                mesh_ptr.vertices.items[vertex_index].position,
                mesh_ptr.vertices.items[vertex_index + 1].position,
                mesh_ptr.vertices.items[vertex_index + 2].position,
            };

            // Go from model to world space
            for (0..triangle.len) |i| {
                var world_view_position: Vector4 = triangle[i];

                world_view_position = Matrix.mat4MulVec4(&world_matrix, &world_view_position);
                world_view_position = Matrix.mat4MulVec4(&view_matrix, &world_view_position);

                triangle[i] = world_view_position;
            }

            // Do backface culling
            if (backFaceCulling(&triangle[0], &triangle[1], &triangle[2])) {
                culled_triangles += 1;
                continue;
            }

            // Go from world to ndc space
            for (0..triangle.len) |i| {
                var projected_point = triangle[i];
                projected_point = Matrix.mat4MulVec4(&self.proj_mat, &projected_point);
                projected_point = Matrix.mat4MulVec4(&screenspace_matrix, &projected_point);

                // Do the perspective divide.
                if (projected_point.w != 0) {
                    projected_point.x /= projected_point.w;
                    projected_point.y /= projected_point.w;
                    projected_point.z /= projected_point.w;
                }

                triangle[i] = projected_point;
            }

            var vertex_a = mesh_ptr.vertices.items[vertex_index];
            var vertex_b = mesh_ptr.vertices.items[vertex_index + 1];
            var vertex_c = mesh_ptr.vertices.items[vertex_index + 2];

            vertex_a.position = triangle[0];
            vertex_b.position = triangle[1];
            vertex_c.position = triangle[2];

            try self.triangle_list.append(Triangle.init(vertex_a, vertex_b, vertex_c));
        }

        const end_vertex_time = std.time.milliTimestamp();
        vertex_time_ms = end_vertex_time - start_time;

        // Render triangles
        for (self.triangle_list.items) |triangle| {
            switch (self.render_mode) {
                RenderMode.rasterized => {
                    Rasterizer.drawTriangle(&self.display, &triangle, &models.items[0].texture);
                },
                RenderMode.wireframe => {
                    Rasterizer.drawTriangleLines(&self.display, &triangle, Color.black);
                },
                RenderMode.points => {
                    Rasterizer.drawTrianglePoints(&self.display, &triangle, Color.black);
                },
            }
        }
        rendered_triangles += @intCast(self.triangle_list.items.len);
        total_triangles += @intCast(mesh_ptr.vertices.items.len / 3);

        const end_pixel_time = std.time.milliTimestamp();
        pixel_time_ms = end_pixel_time - end_vertex_time;
    }

    self.display.present();
    render_time_ns = std.time.milliTimestamp() - start_time;
}

pub fn beginDrawing(self: *Renderer) void {
    culled_triangles = 0;
    total_triangles = 0;
    rendered_triangles = 0;
    vertex_time_ms = 0.0;
    pixel_time_ms = 0.0;

    rl.beginDrawing();
    rl.clearBackground(rl.Color.sky_blue);
    self.display.clearColorBuffer(Color.light_gray);
    self.display.clearDepthBuffer();
}

pub fn endDrawing(self: *Renderer) void {
    rl.endDrawing();
    self.triangle_list.clearRetainingCapacity();
}

pub fn getRenderDiagnostics(self: *Renderer) RenderDiagnostics {
    return RenderDiagnostics.init(
        self.render_mode,
        culled_triangles,
        total_triangles,
        rendered_triangles,
        vertex_time_ms,
        pixel_time_ms,
        render_time_ns,
    );
}

fn backFaceCulling(vector_a: *Vector4, vector_b: *Vector4, vector_c: *Vector4) bool {
    const vector_1 = Vector.vec4ToVec3(vector_a);
    const vector_2 = Vector.vec4ToVec3(vector_b);
    const vector_3 = Vector.vec4ToVec3(vector_c);

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
