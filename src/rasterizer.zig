pub const Rasterizer = @This();

const Display = @import("display.zig");
const Color = @import("color.zig").Color;
const Vector = @import("vector.zig");
const Vertex = @import("vertex.zig");
const Triangle = @import("triangle.zig");
const Texture = @import("texture.zig");
const TextureCoords = @import("texturecoords.zig");

const Vector2 = Vector.Vector2;
const Vector3 = Vector.Vector3;

display: *Display,
width: usize,
height: usize,

pub fn init(display: *Display, width: usize, height: usize) Rasterizer {
    return .{
        .display = display,
        .width = @intCast(width),
        .height = @intCast(height),
    };
}

pub fn drawRectangle(self: *Rasterizer, x_pos: i32, y_pos: i32, width: i32, height: i32, color: Color) void {
    for (0..height) |y| {
        for (0..width) |x| {
            self.display.drawPixel(
                @intCast(y + y_pos),
                @intCast(x + x_pos),
                color,
            );
        }
    }
}

// DDA line drawing algorithm
pub fn drawLine(display: *Display, x0: i32, y0: i32, x1: i32, y1: i32, color: Color) void {
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
        display.drawPixel(
            @intFromFloat(@round(curr_x)),
            @intFromFloat(@round(curr_y)),
            color,
        );
        curr_x += x_increment;
        curr_y += y_increment;
    }
}

pub fn drawTriangleLines(display: *Display, tri: *const Triangle, color: Color) void {
    const x0: i32 = @intFromFloat(tri.vertices[0].position.x);
    const x1: i32 = @intFromFloat(tri.vertices[1].position.x);
    const x2: i32 = @intFromFloat(tri.vertices[2].position.x);

    const y0: i32 = @intFromFloat(tri.vertices[0].position.y);
    const y1: i32 = @intFromFloat(tri.vertices[1].position.y);
    const y2: i32 = @intFromFloat(tri.vertices[2].position.y);

    drawLine(display, x0, y0, x1, y1, color);
    drawLine(display, x1, y1, x2, y2, color);
    drawLine(display, x2, y2, x0, y0, color);
}

pub fn drawTriangle(display: *Display, tri: *const Triangle, texture: *const Texture) void {
    const vertex_a: Vertex = tri.vertices[0];
    const vertex_b: Vertex = tri.vertices[1];
    const vertex_c: Vertex = tri.vertices[2];

    const point_a = Vector.vec4ToVec2(&vertex_a.position);
    const point_b = Vector.vec4ToVec2(&vertex_b.position);
    const point_c = Vector.vec4ToVec2(&vertex_c.position);

    const x_min: usize = @intFromFloat(@floor(@min(@min(point_a.x, point_b.x), point_c.x)));
    const y_min: usize = @intFromFloat(@floor(@min(@min(point_a.y, point_b.y), point_c.y)));

    const x_max: usize = @intFromFloat(@ceil(@max(@max(point_a.x, point_b.x), point_c.x)));
    const y_max: usize = @intFromFloat(@ceil(@max(@max(point_a.y, point_b.y), point_c.y)));

    const delta_w0_col: f32 = point_b.y - point_c.y;
    const delta_w1_col: f32 = point_c.y - point_a.y;
    const delta_w2_col: f32 = point_a.y - point_b.y;

    const delta_w0_row: f32 = point_c.x - point_b.x;
    const delta_w1_row: f32 = point_a.x - point_c.x;
    const delta_w2_row: f32 = point_b.x - point_a.x;

    const area: f32 = edgeCross(&point_a, &point_b, &point_c);

    const bias0: f32 = if (isTopLeft(&point_b, &point_c)) 0 else -0.0001;
    const bias1: f32 = if (isTopLeft(&point_c, &point_a)) 0 else -0.0001;
    const bias2: f32 = if (isTopLeft(&point_a, &point_b)) 0 else -0.0001;

    const point_p: Vector2 = .{
        .x = @as(f32, @floatFromInt(x_min)) + 0.5,
        .y = @as(f32, @floatFromInt(y_min)) + 0.5,
    };
    var w0_row: f32 = edgeCross(&point_b, &point_c, &point_p) + bias0;
    var w1_row: f32 = edgeCross(&point_c, &point_a, &point_p) + bias1;
    var w2_row: f32 = edgeCross(&point_a, &point_b, &point_p) + bias2;

    for (y_min..y_max) |y| {
        var w0: f32 = w0_row;
        var w1: f32 = w1_row;
        var w2: f32 = w2_row;

        for (x_min..x_max) |x| {
            const inside: bool = w0 >= 0 and w1 >= 0 and w2 >= 0;
            if (inside) {
                const alpha: f32 = w0 / area;
                const beta: f32 = w1 / area;
                const gamma: f32 = w2 / area;

                const depth_sample = display.getDepthValue(x, y);

                var interpolated_reciprocal_w: f32 =
                    (1 / vertex_a.position.w) * alpha +
                    (1 / vertex_b.position.w) * beta +
                    (1 / vertex_c.position.w) * gamma;

                var interpolated_uv = interpolateUVCoords(alpha, beta, gamma, tri);

                interpolated_uv.u /= interpolated_reciprocal_w;
                interpolated_uv.v /= interpolated_reciprocal_w;

                const color = texture.sampleTexture(interpolated_uv.u, interpolated_uv.v);

                // adjust 1/w so the pixels that are closer to the camera have smaller values.
                interpolated_reciprocal_w = 1.0 - interpolated_reciprocal_w;

                if (interpolated_reciprocal_w < depth_sample) {
                    display.drawPixel(x, y, color);
                    display.setDepthValue(x, y, interpolated_reciprocal_w);
                }
            }
            w0 += delta_w0_col;
            w1 += delta_w1_col;
            w2 += delta_w2_col;
        }
        w0_row += delta_w0_row;
        w1_row += delta_w1_row;
        w2_row += delta_w2_row;
    }
}

fn edgeCross(a: *const Vector2, b: *const Vector2, p: *const Vector2) f32 {
    const ab: Vector2 = .{ .x = b.x - a.x, .y = b.y - a.y };
    const ap: Vector2 = .{ .x = p.x - a.x, .y = p.y - a.y };

    return ab.x * ap.y - ab.y * ap.x;
}

fn isTopLeft(start: *const Vector2, end: *const Vector2) bool {
    const edge: Vector2 = .{ .x = end.x - start.x, .y = end.y - start.y };
    const is_top_edge: bool = edge.y == 0 and edge.x > 0;
    const is_left_edge: bool = edge.y < 0;

    return is_top_edge or is_left_edge;
}

fn interpolateUVCoords(alpha: f32, beta: f32, gamma: f32, tri: *const Triangle) TextureCoords {
    const interpolated_u: f32 =
        (tri.vertices[0].tex_coord.u / tri.vertices[0].position.w) * alpha +
        (tri.vertices[1].tex_coord.u / tri.vertices[1].position.w) * beta +
        (tri.vertices[2].tex_coord.u / tri.vertices[2].position.w) * gamma;

    // remember to reverse UV mapping on the v axis, because v grows downwards.
    const interpolated_v: f32 =
        ((1.0 - tri.vertices[0].tex_coord.v) / tri.vertices[0].position.w) * alpha +
        ((1.0 - tri.vertices[1].tex_coord.v) / tri.vertices[1].position.w) * beta +
        ((1.0 - tri.vertices[2].tex_coord.v) / tri.vertices[2].position.w) * gamma;

    return .{
        .u = interpolated_u,
        .v = interpolated_v,
    };
}

// fn interpolateColor(alpha: f32, beta: f32, gamma: f32, tri: *const Triangle) Color {
//     const color_1 = tri.vertices[0].color;
//     const color_2 = tri.vertices[1].color;
//     const color_3 = tri.vertices[2].color;

//     const r1: f32 = @floatFromInt(color_1.r);
//     const r2: f32 = @floatFromInt(color_2.r);
//     const r3: f32 = @floatFromInt(color_3.r);

//     const g1: f32 = @floatFromInt(color_1.r);
//     const g2: f32 = @floatFromInt(color_2.r);
//     const g3: f32 = @floatFromInt(color_3.r);

//     const b1: f32 = @floatFromInt(color_1.r);
//     const b2: f32 = @floatFromInt(color_2.r);
//     const b3: f32 = @floatFromInt(color_3.r);

//     const interp_color: Color = .{
//         .a = 255,
//         .r = @intFromFloat(alpha * r1 + beta * r2 + gamma * r3),
//         .g = @intFromFloat(alpha * g1 + beta * g2 + gamma * g3),
//         .b = @intFromFloat(alpha * b1 + beta * b2 + gamma * b3),
//     };

//     return interp_color;
// }
