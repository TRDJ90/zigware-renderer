pub const Gui = @This();

const std = @import("std");
const rl = @import("raylib");

const Camera = @import("camera.zig");

font: rl.Font,
font_size: f32,
width: usize,
height: usize,

pub fn init(width: usize, height: usize, font_size: f32) Gui {
    const font = rl.loadFontEx(
        "assets/fonts/Roboto-Regular.ttf",
        @intFromFloat(font_size),
        null,
    );

    return .{
        .font = font,
        .font_size = font_size,
        .width = width,
        .height = height,
    };
}

pub fn deinit(self: *Gui) void {
    rl.unloadFont(self.font);
}

pub fn drawGui(self: *Gui) void {
    // Draw mouse reticule
    rl.drawCircle(
        @intCast(self.width / 2),
        @intCast(self.height / 2),
        3,
        rl.Color.black,
    );

    // Draw test text
    rl.drawTextEx(self.font, "Test", .{ .x = 20, .y = 70 }, self.font_size, 4, rl.Color.black);
}

pub fn drawDiagnostics(self: *Gui, camera: *Camera) !void {
    rl.drawFPS(10, 10);

    var scratch_pad: [1024]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&scratch_pad);
    const format_text_allocator = fba.allocator();

    const position_text = try std.fmt.allocPrintZ(format_text_allocator, "position x: {d:.3} y: {d:.3} z: {d:.3}", .{ camera.position.x, camera.position.y, camera.position.z });
    rl.drawTextEx(self.font, position_text, .{ .x = 20, .y = 30 }, self.font_size, 4, rl.Color.black);
}
