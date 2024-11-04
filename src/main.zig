const std = @import("std");
const rl = @import("raylib");

const Renderer = @import("renderer.zig");
const RenderMode = Renderer.RenderMode;
const Gui = @import("gui.zig");
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

    const screenWidth: usize = 1280;
    const screenHeight: usize = 720;

    var model_list = std.ArrayList(Model).init(allocator);
    var asset_manager = AssetManager.init(allocator);
    defer asset_manager.deinit();

    const model = try asset_manager.loadModel("./assets/meshes/crab.obj", "./assets/textures/crab.png");
    try model_list.append(model);

    _ = try Window.init(screenWidth, screenHeight, "Test");
    defer Window.deinit();

    var renderer = try Renderer.init(allocator, screenWidth, screenHeight);
    var gui = Gui.init(screenWidth, screenHeight);
    defer gui.deinit();

    var camera: Camera = Camera.init(
        .{ .x = 0, .y = 0.1, .z = -1.8 },
        .{ .x = 0, .y = 0, .z = 1 },
        .{ .x = 0, .y = 0, .z = 0 },
    );

    while (!Window.shouldClose()) {
        var movement: Vector3 = .{ .x = 0, .y = 0, .z = 0 };
        // var yaw: f32 = 0.0;
        // var pitch: f32 = 0.0;

        const delta_time = rl.getFrameTime();

        // const new_mouse = rl.getMousePosition();
        // const delta_mouse = rl.Vector2.subtract(new_mouse, old_mouse);

        // if (delta_mouse.x > 0.00) yaw += 0.5 * delta_time;
        // if (delta_mouse.x < 0.00) yaw -= 0.5 * delta_time;

        // if (delta_mouse.y > 0.00) pitch -= 0.5 * delta_time;
        // if (delta_mouse.y < 0.00) pitch += 0.5 * delta_time;

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

        if (rl.isKeyDown(rl.KeyboardKey.key_one)) {
            renderer.setRenderMode(RenderMode.points);
        }
        if (rl.isKeyDown(rl.KeyboardKey.key_two)) {
            renderer.setRenderMode(RenderMode.rasterized);
        }
        if (rl.isKeyDown(rl.KeyboardKey.key_three)) {
            renderer.setRenderMode(RenderMode.wireframe);
        }

        camera.updateCamera(&movement, 0.0, 0.0);

        renderer.beginDrawing();

        try renderer.render(&camera, &model_list);
        const diagnostics = renderer.getRenderDiagnostics();
        //gui.drawGui();
        try gui.drawDiagnostics(&diagnostics, &camera);

        renderer.endDrawing();
        // old_mouse = new_mouse;
    }
}
