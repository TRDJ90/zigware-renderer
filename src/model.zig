const Model = @This();

const Mesh = @import("mesh.zig");
const Texture = @import("texture.zig");

mesh: Mesh,
texture: Texture,

pub fn init(mesh: Mesh, texture: Texture) Model {
    return .{
        .mesh = mesh,
        .texture = texture,
    };
}
