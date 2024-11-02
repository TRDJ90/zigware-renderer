pub const Triangle = @This();

const Vertex = @import("vertex.zig");

vertices: [3]Vertex,

pub fn init(vertex_a: Vertex, vertex_b: Vertex, vertex_c: Vertex) Triangle {
    return .{
        .vertices = [3]Vertex{ vertex_a, vertex_b, vertex_c },
    };
}
