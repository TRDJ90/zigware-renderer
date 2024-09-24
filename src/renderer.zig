const std = @import("std");
const PixelBuffer = @import("pixel_buffer.zig").PixelBuffer;

//TODO: should probably remove this later on.
// So i don't scatter raylib all over the code base.
const rl = @import("raylib");
const rgui = @import("raygui");

pub const Renderer = struct {
    width: usize,
    height: usize,
    buffer: PixelBuffer,

    render_diag: bool = false,
    render_gui: bool = false,

    showMessageBox: bool = false,

    pub fn init(allocator: std.mem.Allocator, width: usize, height: usize) !Renderer {
        const buffer = try PixelBuffer.init(allocator, width, height);

        return .{
            .buffer = buffer,
            .width = width,
            .height = height,
        };
    }

    pub fn renderDiagnostics(self: *Renderer, show: bool) void {
        self.render_diag = show;
    }

    pub fn renderGui(self: *Renderer, show: bool) void {
        self.render_gui = show;
    }

    pub fn toggleRenderDiagnostics(self: *Renderer) void {
        self.render_diag = !self.render_diag;
    }

    pub fn toggleRenderGui(self: *Renderer) void {
        self.render_gui = !self.render_gui;
    }

    // TODO: Add list of render object later
    pub fn render(self: *Renderer) void {
        var pixels = self.buffer.pixels;

        // Compute checkerboard.
        const width = self.width;
        const height = self.height;

        for (0..height) |y| {
            for (0..width) |x| {
                if (((x / 32 + y / 32) / 1) % 2 == 0) {
                    pixels[y * width + x] = rl.Color.light_gray;
                } else {
                    pixels[y * width + x] = rl.Color.dark_gray;
                }
            }
        }

        rl.beginDrawing();
        rl.clearBackground(rl.Color.dark_gray);

        self.buffer.render();

        if (self.render_diag) {
            rl.drawFPS(10, 10);
        }

        if (self.render_gui) {
            if (rgui.guiButton(.{ .x = 35, .y = 35, .width = 120, .height = 30 }, "Test Message box") > 0) {
                self.showMessageBox = true;
            }

            if (self.showMessageBox) {
                const result = rgui.guiMessageBox(.{ .x = 85, .y = 70, .width = 250, .height = 100 }, "Message Box", "Hi from message box", "Nice;Cool");
                if (result >= 0) {
                    self.showMessageBox = false;
                }
            }
        }

        rl.endDrawing();
    }
};
