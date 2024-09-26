const std = @import("std");

const PixelBuffer = @import("pixel_buffer.zig").PixelBuffer;
const Renderer = @import("renderer.zig").Renderer;
const window = @import("window.zig").Window;

pub fn main() !void {
    // NOTE: Use arena allocator, so i don't have to worry about memory clean up
    // and lifetimes in other parts of the code..
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const screenWidth: u16 = 800;
    const screenHeight: u16 = 600;

    _ = try window.init(screenWidth, screenHeight, "Test");
    defer window.deinit();
    //window.setTargetFPS(60);

    var renderer = try Renderer.init(allocator, screenWidth, screenHeight);
    renderer.renderDiagnostics(true);
    renderer.renderGui(true);

    while (!window.shouldClose()) {
        renderer.render();
    }
}
