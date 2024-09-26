const std = @import("std");
const rl = @import("raylib");
const Color = @import("color.zig").Color;

pub const PixelBuffer = struct {
    allocator: std.mem.Allocator,
    texture: rl.Texture,

    width: usize,
    height: usize,
    pixels: []Color,

    pub fn init(allocator: std.mem.Allocator, width: usize, height: usize) !PixelBuffer {
        const pixels = try allocator.alloc(Color, width * height);

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
            .texture = buffer_texture,
            .width = width,
            .height = height,
            .pixels = pixels,
        };
    }

    pub fn generateCheckerBoard(self: *PixelBuffer, size: u16, color_a: Color, color_b: Color) void {
        const width = self.width;
        const height = self.height;

        for (0..height) |y| {
            for (0..width) |x| {
                if (((x / size + y / size) / 1) % 2 == 0) {
                    self.pixels[y * width + x] = color_a; //Color.light_gray;
                } else {
                    self.pixels[y * width + x] = color_b; //Color.dark_gray;
                }
            }
        }
    }

    pub fn drawRectangle(self: *PixelBuffer, x_pos: u16, y_pos: u16, width: u16, height: u16, color: Color) void {
        for (0..height) |y| {
            for (0..width) |x| {
                self.setPixel(
                    @intCast(y + y_pos),
                    @intCast(x + x_pos),
                    color,
                );
            }
        }
    }

    // DDA line drawing algorithm
    pub fn drawLine(self: *PixelBuffer, x0: i16, y0: i16, x1: i16, y1: i16, color: Color) void {
        const delta_x: i32 = (x1 - x0);
        const delta_y: i32 = (y1 - y0);

        var side_length: i32 = undefined;

        if (@abs(delta_x) >= @abs(delta_y)) {
            side_length = @intCast(@abs(delta_x));
        } else {
            side_length = @intCast(@abs(delta_y));
        }

        const side_length_float: f32 = @floatFromInt(side_length);
        const delta_x_float: f32 = @floatFromInt(delta_x);
        const delta_y_float: f32 = @floatFromInt(delta_y);

        const x_increment: f32 = delta_x_float / side_length_float;
        const y_increment: f32 = delta_y_float / side_length_float;

        var curr_x: f32 = @floatFromInt(x0);
        var curr_y: f32 = @floatFromInt(y0);

        var i: i32 = 0;
        while (i < side_length) : (i += 1) {
            self.setPixel(@intFromFloat(@round(curr_x)), @intFromFloat(@round(curr_y)), color);
            curr_x += x_increment;
            curr_y += y_increment;
        }
    }

    pub fn drawTriangle(self: *PixelBuffer, x0: i16, y0: i16, x1: i16, y1: i16, x2: i16, y2: i16, color: Color) void {
        self.drawLine(x0, y0, x1, y1, color);
        self.drawLine(x1, y1, x2, y2, color);
        self.drawLine(x2, y2, x0, y0, color);
    }

    pub fn getPixels(self: *PixelBuffer) [*]Color {
        return self.pixels.ptr;
    }

    pub fn setPixel(self: *PixelBuffer, x: u16, y: u16, color: Color) void {
        if (x < self.width and x > 0 and y < self.height and y > 0) {
            self.pixels[y * self.width + x] = color;
        }
    }

    pub fn clearBuffer(self: *PixelBuffer, color: Color) void {
        for (0..self.width * self.height) |i| {
            self.pixels[i] = color;
        }
    }

    pub fn render(self: *PixelBuffer) void {
        // update and render pixel buffer.
        rl.updateTexture(self.texture, self.pixels.ptr);
        rl.drawTexture(self.texture, 0, 0, rl.Color.white);
    }
};
