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
const Mesh = @import("mesh.zig").Mesh;

const fov_factor: f32 = 640;
const camera_position: Vector3 = .{ .x = 0, .y = 0, .z = -7 };
var cube_rotation: Vector3 = .{ .x = 0, .y = 0, .z = 0 };

pub const Renderer = struct {
    width: u16,
    height: u16,
    buffer: PixelBuffer,
    triangles_to_render: std.ArrayList(Triangle),

    pub fn init(allocator: std.mem.Allocator, width: u16, height: u16) !Renderer {
        const buffer = try PixelBuffer.init(allocator, width, height);
        const triangles = std.ArrayList(Triangle).init(allocator);

        return .{
            .buffer = buffer,
            .triangles_to_render = triangles,
            .width = width,
            .height = height,
        };
    }

    fn project(point: Vector3) Vector2 {
        const x: f32 = (point.x * fov_factor) / point.z;
        const y: f32 = (point.y * fov_factor) / point.z;

        return .{ .x = x, .y = y };
    }

    pub fn render(self: *Renderer, meshes: std.ArrayList(Mesh)) void {
        self.buffer.clearBuffer(Color.sky_blue);

        const delta_time = rl.getFrameTime();
        cube_rotation.y += 0.5 * delta_time;
        cube_rotation.x += 0.5 * delta_time;
        cube_rotation.z += 0.5 * delta_time;

        for (meshes.items) |mesh| {
            for (mesh.faces.items) |face| {
                const face_vertices = [3]Vector3{
                    mesh.vertices.items[face.a - 1],
                    mesh.vertices.items[face.b - 1],
                    mesh.vertices.items[face.c - 1],
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

                self.triangles_to_render.append(triangle) catch {
                    std.debug.print("Failed to push triangle", .{});
                    continue;
                };
            }
        }

        for (self.triangles_to_render.items) |triangle| {
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

        rl.drawFPS(10, 10);
        rl.endDrawing();

        self.triangles_to_render.clearRetainingCapacity();
    }
};
