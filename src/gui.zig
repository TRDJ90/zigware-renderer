pub const Gui = @This();

const std = @import("std");
const rl = @import("raylib");

const Camera = @import("camera.zig");
const RenderMode = @import("renderer.zig").RenderMode;
const RenderDiagnostics = @import("render_diagnostics.zig");

width: usize,
height: usize,

font_small: rl.Font,
font_medium: rl.Font,
font_large: rl.Font,

pub fn init(width: usize, height: usize) Gui {
    const font_small = rl.loadFontEx(
        "assets/fonts/Roboto-Regular.ttf",
        8,
        null,
    );
    const font_medium = rl.loadFontEx(
        "assets/fonts/Roboto-Regular.ttf",
        12,
        null,
    );
    const font_large = rl.loadFontEx(
        "assets/fonts/Roboto-Regular.ttf",
        16,
        null,
    );

    return .{
        .font_small = font_small,
        .font_medium = font_medium,
        .font_large = font_large,
        .width = width,
        .height = height,
    };
}

pub fn deinit(self: *Gui) void {
    rl.unloadFont(self.font_small);
    rl.unloadFont(self.font_medium);
    rl.unloadFont(self.font_large);
}

pub fn drawGui(self: *Gui) void {
    rl.drawFPS(10, 10);

    //Draw mouse reticule
    rl.drawCircle(
        @intCast(self.width / 2),
        @intCast(self.height / 2),
        3,
        rl.Color.black,
    );
}

pub fn drawDiagnostics(self: *Gui, render_diagnostics: *const RenderDiagnostics, camera: *const Camera) !void {
    var scratch_pad: [1024]u8 = undefined;
    @memset(&scratch_pad, 0);

    const font = self.font_medium;

    var fba = std.heap.FixedBufferAllocator.init(&scratch_pad);
    const format_text_allocator = fba.allocator();

    const position_text = try std.fmt.allocPrintZ(format_text_allocator, "position x: {d:.3} y: {d:.3} z: {d:.3}", .{ camera.position.x, camera.position.y, camera.position.z });
    rl.drawTextEx(font, position_text, .{ .x = 20, .y = 30 }, @floatFromInt(font.baseSize), 4, rl.Color.black);

    const render_mode = try std.fmt.allocPrintZ(format_text_allocator, "render mode: {s}", .{std.enums.tagName(RenderMode, render_diagnostics.mode).?});
    rl.drawTextEx(font, render_mode, .{ .x = 20, .y = 40 }, @floatFromInt(font.baseSize), 4, rl.Color.black);

    const culled_triangles = try std.fmt.allocPrintZ(format_text_allocator, "culled triangles: {any}", .{render_diagnostics.culled_triangles});
    rl.drawTextEx(font, culled_triangles, .{ .x = 20, .y = 50 }, @floatFromInt(font.baseSize), 4, rl.Color.black);

    const rendered_triangles = try std.fmt.allocPrintZ(format_text_allocator, "Rendered triangles: {any}", .{render_diagnostics.rendered_triangles});
    rl.drawTextEx(font, rendered_triangles, .{ .x = 20, .y = 60 }, @floatFromInt(font.baseSize), 4, rl.Color.black);

    const total_triangles = try std.fmt.allocPrintZ(format_text_allocator, "Total triangles: {any}", .{render_diagnostics.total_triangles});
    rl.drawTextEx(font, total_triangles, .{ .x = 20, .y = 70 }, @floatFromInt(font.baseSize), 4, rl.Color.black);

    // Render timings
    rl.drawTextEx(font, "Timing cpu performance: ", .{ .x = 20, .y = 80 }, @floatFromInt(font.baseSize), 4, rl.Color.black);

    const vertex_time = try std.fmt.allocPrintZ(format_text_allocator, "- vertex time: {any}ms", .{render_diagnostics.vertex_time_ms});
    rl.drawTextEx(font, vertex_time, .{ .x = 25, .y = 90 }, @floatFromInt(font.baseSize), 4, rl.Color.black);

    const pixel_time = try std.fmt.allocPrintZ(format_text_allocator, "- pixel time: {any}ms", .{render_diagnostics.pixel_time_ms});
    rl.drawTextEx(font, pixel_time, .{ .x = 25, .y = 100 }, @floatFromInt(font.baseSize), 4, rl.Color.black);

    const render_time = try std.fmt.allocPrintZ(format_text_allocator, "- render time: {any}ms ({any}fps)", .{ render_diagnostics.render_time_ms, (@divFloor(1000, render_diagnostics.render_time_ms)) });
    rl.drawTextEx(font, render_time, .{ .x = 25, .y = 110 }, @floatFromInt(font.baseSize), 4, rl.Color.black);
}
