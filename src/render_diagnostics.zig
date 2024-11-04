pub const RenderDiagnostics = @This();
pub const RenderMode = @import("renderer.zig").RenderMode;

mode: RenderMode,
culled_triangles: u32,
total_triangles: u32,
rendered_triangles: u32,
vertex_time_ms: i64,
pixel_time_ms: i64,
render_time_ms: i64,

pub fn init(
    mode: RenderMode,
    culled_triangles: u32,
    total_triangles: u32,
    rendered_triangles: u32,
    vertex_time_ms: i64,
    pixel_time_ms: i64,
    render_time_ms: i64,
) RenderDiagnostics {
    return .{
        .mode = mode,
        .culled_triangles = culled_triangles,
        .total_triangles = total_triangles,
        .rendered_triangles = rendered_triangles,
        .vertex_time_ms = vertex_time_ms,
        .pixel_time_ms = pixel_time_ms,
        .render_time_ms = render_time_ms,
    };
}
