const std = @import("std");
const rl = @import("raylib");

const Renderer = @import("renderer.zig");
const Window = @import("window.zig");

const AssetManager = @import("asset_manager.zig");
const Vector3 = @import("vector.zig").Vector3;
const Mesh = @import("mesh.zig");
const Model = @import("model.zig");
const Camera = @import("camera.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const screenWidth: u16 = 1280;
    const screenHeight: u16 = 720;

    var model_list = std.ArrayList(Model).init(allocator);
    var asset_manager = AssetManager.init(allocator);
    defer asset_manager.deinit();

    const model = try asset_manager.loadModel("./assets/f22.obj", "./assets/f22.png");
    try model_list.append(model);

    _ = try Window.init(screenWidth, screenHeight, "Test");
    defer Window.deinit();

    var renderer = try Renderer.init(allocator, screenWidth, screenHeight);
    var old_mouse = rl.getMousePosition();

    var camera: Camera = Camera.init(
        .{ .x = 0.5, .y = 0.5, .z = -4 },
        .{ .x = 0, .y = 0, .z = 1 },
        .{ .x = 0, .y = 0, .z = 0 },
    );

    while (!Window.shouldClose()) {
        var movement: Vector3 = .{ .x = 0, .y = 0, .z = 0 };
        var yaw: f32 = 0.0;
        var pitch: f32 = 0.0;

        const delta_time = rl.getFrameTime();

        const new_mouse = rl.getMousePosition();
        const delta_mouse = rl.Vector2.subtract(new_mouse, old_mouse);

        if (delta_mouse.x > 0.00) yaw += 0.5 * delta_time;
        if (delta_mouse.x < 0.00) yaw -= 0.5 * delta_time;

        if (delta_mouse.y > 0.00) pitch -= 0.5 * delta_time;
        if (delta_mouse.y < 0.00) pitch += 0.5 * delta_time;

        if (rl.isKeyDown(rl.KeyboardKey.key_w)) {
            movement.z += 5.0 * delta_time;
        }
        if (rl.isKeyDown(rl.KeyboardKey.key_s)) {
            movement.z -= 5.0 * delta_time;
        }
        if (rl.isKeyDown(rl.KeyboardKey.key_a)) {
            movement.x -= 5.0 * delta_time;
        }
        if (rl.isKeyDown(rl.KeyboardKey.key_d)) {
            movement.x += 5.0 * delta_time;
        }
        if (rl.isKeyDown(rl.KeyboardKey.key_up)) {
            movement.y -= 5.0 * delta_time;
        }
        if (rl.isKeyDown(rl.KeyboardKey.key_down)) {
            movement.y += 5.0 * delta_time;
        }

        camera.updateCamera(&movement, yaw, pitch);
        try renderer.render(&camera, &model_list);
        old_mouse = new_mouse;
    }
}
