pub const Texture = @This();

const std = @import("std");
const Color = @import("color.zig").Color;

width: usize,
height: usize,
allocator: std.mem.Allocator,
pixels: []Color,

pub fn init(allocator: std.mem.Allocator, width: usize, height: usize) !Texture {
    var texture: Texture = undefined;
    texture.width = width;
    texture.height = height;
    texture.allocator = allocator;

    texture.pixels = try allocator.alloc(Color, width * height);
    return texture;
}

pub fn deinit(self: *Texture) void {
    self.allocator.free(self.pixels);
}

pub fn sampleTexture(self: *const Texture, u: f32, v: f32) Color {
    const width_f32 = @as(f32, @floatFromInt(self.width));
    const height_f32 = @as(f32, @floatFromInt(self.height));

    const x_coord: usize = @abs(@as(usize, @intFromFloat(u * width_f32))) % self.width;
    const y_coord: usize = @abs(@as(usize, @intFromFloat(v * height_f32))) % self.height;
    const index: usize = self.width * y_coord + x_coord;

    return self.pixels[index];
}
