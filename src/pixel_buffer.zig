const std = @import("std");
const rl = @import("raylib");

pub const PixelBuffer = struct {
    allocator: std.mem.Allocator,
    buffer: rl.Texture,

    width: usize,
    height: usize,
    pixels: []rl.Color,

    pub fn init(allocator: std.mem.Allocator, width: usize, height: usize) !PixelBuffer {
        const pixels = try allocator.alloc(rl.Color, width * height);

        const image: rl.Image = .{
            .data = pixels.ptr,
            .width = @intCast(width),
            .height = @intCast(height),
            .format = rl.PixelFormat.pixelformat_uncompressed_r8g8b8a8,
            .mipmaps = 1,
        };

        const buffer_texture: rl.Texture = rl.loadTextureFromImage(image);

        return .{
            .allocator = allocator,
            .buffer = buffer_texture,
            .width = width,
            .height = height,
            .pixels = pixels,
        };
    }

    pub fn getPixels(self: *PixelBuffer) [*]rl.Color {
        return self.pixels.ptr;
    }

    pub fn setPixel(self: *PixelBuffer, x: i32, y: i32, color: rl.Color) void {
        self.pixels[y * self.width + x] = color;
    }

    pub fn render(self: *PixelBuffer) void {
        // update and render pixel buffer.
        rl.updateTexture(self.buffer, self.pixels.ptr);
        rl.drawTexture(self.buffer, 0, 0, rl.Color.white);
    }
};
