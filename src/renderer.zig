const std = @import("std");
const PixelBuffer = @import("pixel_buffer.zig").PixelBuffer;

const rl = @import("raylib");
const rgui = @import("raygui");
const Color = @import("color.zig").Color;

const Vector = @import("vector.zig");
const Vector3 = @import("vector.zig").Vector3;
const Vector2 = @import("vector.zig").Vector2;

const Face = @import("triangl.zig").Face;
const Triangle = @import("triangl.zig").Triangle;
const Mesh = @import("mesh.zig");

const fov_factor: f32 = 640;
const camera_position: Vector3 = .{ .x = 0, .y = 0, .z = -7 };
var cube_rotation: Vector3 = .{ .x = 0, .y = 0, .z = 0 };

pub const Renderer = struct {
    width: u16,
    height: u16,
    buffer: PixelBuffer,

    render_diag: bool = false,
    render_gui: bool = false,
    showMessageBox: bool = false,

    triangles_to_render: []Triangle,

    pub fn init(allocator: std.mem.Allocator, width: u16, height: u16) !Renderer {
        const buffer = try PixelBuffer.init(allocator, width, height);
        const triangles = try allocator.alloc(Triangle, 12);

        return .{
            .buffer = buffer,
            .triangles_to_render = triangles,
            .width = width,
            .height = height,
        };
    }

    pub fn renderDiagnostics(self: *Renderer, show: bool) void {
        self.render_diag = show;
    }

    pub fn renderGui(self: *Renderer, show: bool) void {
        self.render_gui = show;
    }

    pub fn toggleRenderDiagnostics(self: *Renderer) void {
        self.render_diag = !self.render_diag;
    }

    pub fn toggleRenderGui(self: *Renderer) void {
        self.render_gui = !self.render_gui;
    }

    fn project(point: Vector3) Vector2 {
        const x: f32 = (point.x * fov_factor) / point.z;
        const y: f32 = (point.y * fov_factor) / point.z;

        return .{ .x = x, .y = y };
    }

    // TODO: Add list of render object later
    pub fn render(self: *Renderer) void {
        self.buffer.clearBuffer(Color.sky_blue);

        const delta_time = rl.getFrameTime();
        cube_rotation.y += 0.5 * delta_time;
        cube_rotation.x += 0.5 * delta_time;
        cube_rotation.z += 0.5 * delta_time;

        // Render vectors with perspective projection
        for (Mesh.mesh_faces, 0..) |face, i| {
            const face_vertices = [3]Vector3{
                Mesh.mesh_vertices[face.a - 1],
                Mesh.mesh_vertices[face.b - 1],
                Mesh.mesh_vertices[face.c - 1],
            };

            var triangle: Triangle = undefined;

            for (face_vertices, 0..) |point, j| {
                var point3D = point;

                point3D = Vector.vec3RotateX(point3D, cube_rotation.x);
                point3D = Vector.vec3RotateY(point3D, cube_rotation.y);
                point3D = Vector.vec3RotateZ(point3D, cube_rotation.z);

                point3D.z -= camera_position.z;

                var projected_point = project(point3D);
                projected_point.x += @floatFromInt(@divTrunc(self.width, 2));
                projected_point.y += @floatFromInt(@divTrunc(self.height, 2));

                triangle.points[j] = projected_point;
            }

            self.triangles_to_render[i] = triangle;
        }

        for (self.triangles_to_render) |triangle| {
            self.buffer.drawTriangle(
                @intFromFloat(triangle.points[0].x),
                @intFromFloat(triangle.points[0].y),
                @intFromFloat(triangle.points[1].x),
                @intFromFloat(triangle.points[1].y),
                @intFromFloat(triangle.points[2].x),
                @intFromFloat(triangle.points[2].y),
                Color.black,
            );
        }

        rl.beginDrawing();
        rl.clearBackground(rl.Color.sky_blue);

        self.buffer.render();

        if (self.render_diag) {
            rl.drawFPS(10, 10);
        }

        if (self.render_gui) {
            if (rgui.guiButton(.{ .x = 35, .y = 35, .width = 120, .height = 30 }, "Test Message box") > 0) {
                self.showMessageBox = true;
            }

            if (self.showMessageBox) {
                const result = rgui.guiMessageBox(.{ .x = 85, .y = 70, .width = 250, .height = 100 }, "Message Box", "Hi from message box", "Nice;Cool");
                if (result >= 0) {
                    self.showMessageBox = false;
                }
            }
        }

        rl.endDrawing();
    }
};
