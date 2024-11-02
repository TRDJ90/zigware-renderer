pub const Window = @This();

const rl = @import("raylib");

width: usize,
height: usize,

pub fn init(screen_width: usize, screen_height: usize, title: [*:0]const u8) !Window {
    rl.initWindow(@intCast(screen_width), @intCast(screen_height), title);

    return .{
        .width = screen_width,
        .height = screen_height,
    };
}

pub fn deinit() void {
    rl.closeWindow();
}

pub fn shouldClose() bool {
    return rl.windowShouldClose();
}

pub fn setTargetFPS(fps: i32) void {
    rl.setTargetFPS(fps);
}
