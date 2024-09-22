const std = @import("std");
const rl = @import("raylib");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const screenWidth = 800;
    const screenHeight = 600;

    rl.initWindow(screenWidth, screenHeight, "Test raylib");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    // Allocate pixels
    const pixels: []rl.Color = try allocator.alloc(rl.Color, screenWidth * screenHeight);

    // Compute checkerboard.
    for (0..screenHeight) |y| {
        for (0..screenWidth) |x| {
            if (((x / 32 + y / 32) / 1) % 2 == 0) {
                pixels[y * screenWidth + x] = rl.Color.orange;
            } else {
                pixels[y * screenWidth + x] = rl.Color.gold;
            }
        }
    }

    // dump pixel data into image format
    const pixel_image = .{
        .data = pixels.ptr,
        .width = screenWidth,
        .height = screenHeight,
        .format = rl.PixelFormat.pixelformat_uncompressed_r8g8b8a8,
        .mipmaps = 1,
    };

    // load image data into texture.
    const pixel_texture = rl.loadTextureFromImage(pixel_image);

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.dark_gray);

        // render pixel buffer
        rl.drawTexture(
            pixel_texture,
            @divFloor(screenWidth, 2) - @divFloor(pixel_texture.width, 2),
            @divFloor(screenHeight, 2) - @divFloor(pixel_texture.height, 2),
            rl.fade(
                rl.Color.white,
                0.5,
            ),
        );
    }
}
