const std = @import("std");

const PixelBuffer = @import("pixel_buffer.zig").PixelBuffer;
const Renderer = @import("renderer.zig").Renderer;
const Window = @import("window.zig").Window;

const AssetManager = @import("asset_manager.zig").AssetManager;
const Mesh = @import("mesh.zig").Mesh;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const screenWidth: u16 = 800;
    const screenHeight: u16 = 600;

    var asset_manager = AssetManager.init(allocator);
    defer asset_manager.deinit();

    var mesh_list = std.ArrayList(Mesh).init(allocator);
    const mesh: Mesh = try asset_manager.loadObj();
    try mesh_list.append(mesh);

    _ = try Window.init(screenWidth, screenHeight, "Test");
    defer Window.deinit();

    var renderer = try Renderer.init(allocator, screenWidth, screenHeight);

    while (!Window.shouldClose()) {
        renderer.render(mesh_list);
    }
}
