const std = @import("std");
const Display = @import("display.zig").Display;
const Rasterizer = @import("rasterizer.zig").Rasterizer;
const Camera = @import("camera.zig").FpsCamera;

const rl = @import("raylib");
const rgui = @import("raygui");
const Color = @import("color.zig").Color;

const Vector = @import("vector.zig");
const Vector2 = Vector.Vector2;
const Vector3 = Vector.Vector3;
const Vector4 = Vector.Vector4;

const Vertex = @import("vertex.zig").Vertex;
const Face = @import("triangle.zig").Face;
const Triangle = @import("triangle.zig").Triangle;
const Mesh = @import("mesh.zig").Mesh;
const Light = @import("light.zig").Light;

const Matrix = @import("matrix.zig");
const Matrix4x4 = Matrix.Matrix4x4;

const camera_position: Vector3 = .{ .x = 0, .y = 0, .z = 0 };

pub const Renderer = struct {
    width: u16,
    height: u16,
    display: Display,
    rasterizer: Rasterizer,
    triangles_to_render: std.ArrayList(Triangle),
    proj_mat: Matrix4x4,
    camera: Camera,

    pub fn init(allocator: std.mem.Allocator, width: u16, height: u16) !Renderer {
        var display = try Display.init(allocator, width, height);
        const rasterizer = Rasterizer.init(&display, width, height);
        const triangles = std.ArrayList(Triangle).init(allocator);

        const fov: f32 = std.math.pi / 3.0;
        const width_f32: f32 = @floatFromInt(width);
        const height_f32: f32 = @floatFromInt(height);

        const aspect: f32 = width_f32 / height_f32;
        const znear: f32 = 0.1;
        const zfar: f32 = 100.0;

        const camera: Camera = .{
            .position = .{ .x = 0, .y = 2, .z = 0 },
            .direction = .{ .x = 0, .y = 0, .z = 1 },
            .forward_velocity = .{ .x = 0, .y = 0, .z = 1.0 },
            .yaw = 0,
            .pitch = 0,
        };

        const proj_mat = Matrix.makePerspectiveMat4(fov, aspect, znear, zfar);

        return .{
            .display = display,
            .rasterizer = rasterizer,
            .triangles_to_render = triangles,
            .camera = camera,
            .proj_mat = proj_mat,
            .width = width,
            .height = height,
        };
    }

    pub fn render(self: *Renderer, meshes: *std.ArrayList(Mesh), input: Vector3, yaw: f32, pitch: f32) !void {
        const delta_time = rl.getFrameTime();

        for (meshes.items) |*mesh| {
            mesh.rotation.y += 0.5 * delta_time;
            mesh.rotation.x += 0.5 * delta_time;
            mesh.rotation.z += 0.5 * delta_time;
            mesh.translation.z = 9.0;

            const scale_mat: Matrix4x4 = Matrix.scaleMat4x4(mesh.scale.x, mesh.scale.y, mesh.scale.z);
            const translation_mat: Matrix4x4 = Matrix.translateMat4x4(mesh.translation.x, mesh.translation.y, mesh.translation.z);
            const rotation_mat_x: Matrix4x4 = Matrix.rotationMat4x4X(mesh.rotation.x);
            const rotation_mat_y: Matrix4x4 = Matrix.rotationMat4x4Y(mesh.rotation.y);
            const rotation_mat_z: Matrix4x4 = Matrix.rotationMat4x4Z(mesh.rotation.z);

            var target: Vector3 = .{ .x = 0, .y = 0, .z = 1 };

            self.camera.position.x += input.x * delta_time;
            self.camera.position.y += input.y * delta_time;
            self.camera.position.z += input.z * delta_time;

            self.camera.yaw += yaw * delta_time;
            self.camera.pitch += pitch * delta_time;

            const camera_yaw_rotation = Matrix.rotationMat4x4Y(self.camera.yaw);
            const camera_pitch_rotation = Matrix.rotationMat4x4X(self.camera.pitch);

            var camera_rotation = Matrix.identityMat4x4();
            camera_rotation = Matrix.mat4MulMat4(camera_pitch_rotation, camera_rotation);
            camera_rotation = Matrix.mat4MulMat4(camera_yaw_rotation, camera_rotation);

            const target_4d = Vector.vec3ToVec4(&target);
            const camera_direction = Matrix.mat4MulVec4(&camera_rotation, &target_4d);
            self.camera.direction = Vector.vec4ToVec3(&camera_direction);

            target = Vector.addVec3(&self.camera.position, &self.camera.direction);
            const up: Vector3 = .{ .x = 0, .y = 1, .z = 0 };

            const view_matrix: Matrix4x4 = Matrix.LookAtMat4(
                self.camera.position,
                target,
                up,
            );

            var world_matrix = Matrix.identityMat4x4();
            world_matrix = Matrix.mat4MulMat4(scale_mat, world_matrix);
            world_matrix = Matrix.mat4MulMat4(rotation_mat_z, world_matrix);
            world_matrix = Matrix.mat4MulMat4(rotation_mat_y, world_matrix);
            world_matrix = Matrix.mat4MulMat4(rotation_mat_x, world_matrix);
            world_matrix = Matrix.mat4MulMat4(translation_mat, world_matrix);

            for (mesh.faces.items) |face| {
                var transformed_vertices: [3]Vector4 = undefined;
                var projected_vertices: [3]Vector4 = undefined;

                const face_vertices = [3]Vertex{
                    mesh.vertices.items[face.a],
                    mesh.vertices.items[face.b],
                    mesh.vertices.items[face.c],
                };

                for (face_vertices, 0..) |point, i| {
                    var point4D = point.position;
                    point4D = Matrix.mat4MulVec4(&world_matrix, &point4D);
                    point4D = Matrix.mat4MulVec4(&view_matrix, &point4D);
                    transformed_vertices[i] = point4D;
                }

                // Check backface culling before adding triangle to list of triangles
                // we want to render.
                const vector_a = Vector.vec4ToVec3(&transformed_vertices[0]);
                const vector_b = Vector.vec4ToVec3(&transformed_vertices[1]);
                const vector_c = Vector.vec4ToVec3(&transformed_vertices[2]);

                var vector_ab = Vector.subVec3(&vector_b, &vector_a);
                var vector_ac = Vector.subVec3(&vector_c, &vector_a);

                Vector.normalizeVec3(&vector_ab);
                Vector.normalizeVec3(&vector_ac);

                var normal = Vector.crossVec3(&vector_ab, &vector_ac);
                Vector.normalizeVec3(&normal);

                const origin: Vector3 = .{ .x = 0, .y = 0, .z = 0 };
                const camera_ray = Vector.subVec3(&origin, &vector_a);
                const dot_normal_camera: f32 = Vector.dotVec3(&normal, &camera_ray);

                if (dot_normal_camera < 0) {
                    continue;
                }

                for (transformed_vertices, 0..) |point, i| {
                    var projected_point = Matrix.mat4MulVec4(&self.proj_mat, &point);

                    if (projected_point.w != 0) {
                        projected_point.x /= projected_point.w;
                        projected_point.y /= projected_point.w;
                        projected_point.z /= projected_point.w;
                    }

                    projected_point.y *= -1.0;

                    projected_point.x *= @floatFromInt(@divTrunc(self.width, 2));
                    projected_point.y *= @floatFromInt(@divTrunc(self.height, 2));

                    projected_point.x += @floatFromInt(@divTrunc(self.width, 2));
                    projected_point.y += @floatFromInt(@divTrunc(self.height, 2));

                    projected_vertices[i] = projected_point;
                }

                const ligth: Light = .{ .direction = .{ .x = 0, .y = 0, .z = -1 } };
                const light_intensity: f32 = Vector.dotVec3(&normal, &ligth.direction);

                const point1 = projected_vertices[0];
                const point2 = projected_vertices[1];
                const point3 = projected_vertices[2];

                const tri: Triangle = .{
                    .vertices = [_]Vertex{
                        .{ .position = point1, .color = face_vertices[0].color },
                        .{ .position = point2, .color = face_vertices[1].color },
                        .{ .position = point3, .color = face_vertices[2].color },
                    },
                    .color = lightApplyIntensity(face.color, light_intensity),
                };

                try self.triangles_to_render.append(tri);
            }
        }

        rl.beginDrawing();
        rl.clearBackground(rl.Color.sky_blue);

        // Render triangles
        for (self.triangles_to_render.items) |triangle| {
            Rasterizer.drawTriangle(&self.display, &triangle);
            Rasterizer.drawTriangleLines(&self.display, &triangle, Color.black);
        }

        self.display.present();

        rl.drawFPS(10, 10);
        rl.drawCircle(self.width / 2, self.height / 2, 3, rl.Color.dark_gray);
        rl.endDrawing();

        self.triangles_to_render.clearRetainingCapacity();
        self.display.clearColorBuffer(Color.white);
        self.display.clearDepthBuffer();
    }
};

// Simple surface light shader.
fn lightApplyIntensity(color: Color, intensity: f32) Color {
    var percentage = intensity;

    if (percentage < 0.0) percentage = 0.0;
    if (percentage > 1.0) percentage = 1.0;

    var red: f32 = @floatFromInt(color.r);
    var green: f32 = @floatFromInt(color.g);
    var blue: f32 = @floatFromInt(color.b);

    red = red * percentage;
    green = green * percentage;
    blue = blue * percentage;

    return .{
        .a = color.a,
        .r = @intFromFloat(red),
        .g = @intFromFloat(green),
        .b = @intFromFloat(blue),
    };
}
