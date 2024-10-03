const std = @import("std");
const swap = std.mem.swap;
const rl = @import("raylib");
const Color = @import("color.zig").Color;

pub const Display = struct {
    allocator: std.mem.Allocator,
    display: rl.Texture,

    width: usize,
    height: usize,
    color_buffer: []Color,
    depth_buffer: []f32,

    pub fn init(allocator: std.mem.Allocator, width: usize, height: usize) !Display {
        const pixels = try allocator.alloc(Color, width * height);
        const depth = try allocator.alloc(f32, width * height);

        const image: rl.Image = .{
            .data = pixels.ptr,
            .width = @intCast(width),
            .height = @intCast(height),
            .format = rl.PixelFormat.pixelformat_uncompressed_r8g8b8a8,
            .mipmaps = 1,
        };

        const display_texture: rl.Texture = rl.loadTextureFromImage(image);

        return .{
            .allocator = allocator,
            .display = display_texture,
            .width = @intCast(width),
            .height = @intCast(height),
            .color_buffer = pixels,
            .depth_buffer = depth,
        };
    }

    pub fn drawPixel(self: *Display, x: usize, y: usize, color: Color) void {
        self.color_buffer[y * self.width + x] = color;
    }

    pub fn getDepthValue(self: *Display, x: usize, y: usize) f32 {
        if (x < self.width and x > 0 and y < self.height and y > 0) {
            return self.depth_buffer[y * self.width + x];
        }
        return 0.0;
    }

    pub fn clearColorBuffer(self: *Display, color: Color) void {
        const height: usize = @intCast(self.height);
        const width: usize = @intCast(self.width);
        for (0..height) |y| {
            for (0..width) |x| {
                self.color_buffer[(y * width + x)] = color;
            }
        }
    }

    pub fn clearDepthBuffer(self: *Display) void {
        const range: usize = @intCast(self.width * self.height);
        for (0..range) |i| {
            self.depth_buffer[i] = 1.0;
        }
    }

    pub fn present(self: *Display) void {
        // update and render pixel buffer with Ray lib.
        rl.updateTexture(self.display, self.color_buffer.ptr);
        rl.drawTexture(self.display, 0, 0, rl.Color.white);
    }
};
