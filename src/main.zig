const std = @import("std");
const rl = @import("raylib");

const Renderer = @import("renderer.zig").Renderer;
const Window = @import("window.zig").Window;

const AssetManager = @import("asset_manager.zig").AssetManager;
const Vector3 = @import("vector.zig").Vector3;
const Mesh = @import("mesh.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const screenWidth: u16 = 900;
    const screenHeight: u16 = 900;

    var asset_manager = AssetManager.init(allocator);
    defer asset_manager.deinit();
    var mesh_list = std.ArrayList(Mesh.Mesh).init(allocator);

    const cube = try Mesh.loadCubeMeshData(allocator);
    try mesh_list.append(cube);

    _ = try Window.init(screenWidth, screenHeight, "Test");
    defer Window.deinit();

    var renderer = try Renderer.init(allocator, screenWidth, screenHeight);
    var old_mouse = rl.getMousePosition();

    while (!Window.shouldClose()) {
        var movement: Vector3 = .{ .x = 0, .y = 0, .z = 0 };
        var yaw: f32 = 0.0;
        var pitch: f32 = 0.0;

        const new_mouse = rl.getMousePosition();
        const delta_mouse = rl.Vector2.subtract(new_mouse, old_mouse);

        std.debug.print("{any}\n", .{delta_mouse});

        if (delta_mouse.x > 0.00) yaw += 0.5;
        if (delta_mouse.x < 0.00) yaw -= 0.5;

        if (delta_mouse.y > 0.00) pitch -= 0.5;
        if (delta_mouse.y < 0.00) pitch += 0.5;

        if (rl.isKeyDown(rl.KeyboardKey.key_w)) {
            movement.z += 5.0;
        }
        if (rl.isKeyDown(rl.KeyboardKey.key_s)) {
            movement.z -= 5.0;
        }
        if (rl.isKeyDown(rl.KeyboardKey.key_a)) {
            movement.x -= 5.0;
        }
        if (rl.isKeyDown(rl.KeyboardKey.key_d)) {
            movement.x += 5.0;
        }
        if (rl.isKeyDown(rl.KeyboardKey.key_up)) {
            movement.y -= 5.0;
        }
        if (rl.isKeyDown(rl.KeyboardKey.key_down)) {
            movement.y += 5.0;
        }

        std.debug.print("delta: {any} yaw: {any}, pitch: {any}\n", .{ delta_mouse, yaw, pitch });
        try renderer.render(&mesh_list, movement, yaw, pitch);

        old_mouse = new_mouse;
    }
}
