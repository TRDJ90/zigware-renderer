const std = @import("std");
const lerp = std.math.lerp;

const Vector = @import("vector.zig");
const Vector3 = Vector.Vector3;

const Vertex = @import("vertex.zig").Vertex;
const Triangle = @import("triangle.zig").Triangle;

pub const max_num_poly_vertices: usize = 10;
pub const max_num_poly_triangles: usize = 10;

pub const Planes = enum(u8) {
    LEFT_FRUSTUM_PLANE = 0,
    RIGHT_FRUSTUM_PLANE = 1,
    TOP_FRUSTUM_PLANE = 2,
    BOTTOM_FRUSTUM_PLANE = 3,
    NEAR_FRUSTUM_PLANE = 4,
    FAR_FRUSTUM_PLANE = 5,
};

pub const Plane = struct {
    point: Vector3,
    normal: Vector3,
};

pub const Polygon = struct {
    vertices: [max_num_poly_vertices]Vertex,
    num_vertices: usize,
};

var frustum_planes: [6]Plane = undefined;

pub fn init_frustum_planes(fov_x: f32, fov_y: f32, znear: f32, zfar: f32) void {
    const cos_half_fov_x = std.math.cos(fov_x / 2);
    const sin_half_fov_x = std.math.sin(fov_x / 2);
    const cos_half_fov_y = std.math.cos(fov_y / 2);
    const sin_half_fov_y = std.math.sin(fov_y / 2);

    frustum_planes[@intFromEnum(Planes.LEFT_FRUSTUM_PLANE)].point = .{ .x = 0, .y = 0, .z = 0 };
    frustum_planes[@intFromEnum(Planes.LEFT_FRUSTUM_PLANE)].normal.x = cos_half_fov_x;
    frustum_planes[@intFromEnum(Planes.LEFT_FRUSTUM_PLANE)].normal.y = 0;
    frustum_planes[@intFromEnum(Planes.LEFT_FRUSTUM_PLANE)].normal.z = sin_half_fov_x;

    frustum_planes[@intFromEnum(Planes.RIGHT_FRUSTUM_PLANE)].point = .{ .x = 0, .y = 0, .z = 0 };
    frustum_planes[@intFromEnum(Planes.RIGHT_FRUSTUM_PLANE)].normal.x = -cos_half_fov_x;
    frustum_planes[@intFromEnum(Planes.RIGHT_FRUSTUM_PLANE)].normal.y = 0;
    frustum_planes[@intFromEnum(Planes.RIGHT_FRUSTUM_PLANE)].normal.z = sin_half_fov_x;

    frustum_planes[@intFromEnum(Planes.TOP_FRUSTUM_PLANE)].point = .{ .x = 0, .y = 0, .z = 0 };
    frustum_planes[@intFromEnum(Planes.TOP_FRUSTUM_PLANE)].normal.x = 0;
    frustum_planes[@intFromEnum(Planes.TOP_FRUSTUM_PLANE)].normal.y = -cos_half_fov_y;
    frustum_planes[@intFromEnum(Planes.TOP_FRUSTUM_PLANE)].normal.z = sin_half_fov_y;

    frustum_planes[@intFromEnum(Planes.BOTTOM_FRUSTUM_PLANE)].point = .{ .x = 0, .y = 0, .z = 0 };
    frustum_planes[@intFromEnum(Planes.BOTTOM_FRUSTUM_PLANE)].normal.x = 0;
    frustum_planes[@intFromEnum(Planes.BOTTOM_FRUSTUM_PLANE)].normal.y = cos_half_fov_y;
    frustum_planes[@intFromEnum(Planes.BOTTOM_FRUSTUM_PLANE)].normal.z = sin_half_fov_y;

    frustum_planes[@intFromEnum(Planes.NEAR_FRUSTUM_PLANE)].point = .{ .x = 0, .y = 0, .z = znear };
    frustum_planes[@intFromEnum(Planes.NEAR_FRUSTUM_PLANE)].normal.x = 0;
    frustum_planes[@intFromEnum(Planes.NEAR_FRUSTUM_PLANE)].normal.y = 0;
    frustum_planes[@intFromEnum(Planes.NEAR_FRUSTUM_PLANE)].normal.z = 1;

    frustum_planes[@intFromEnum(Planes.FAR_FRUSTUM_PLANE)].point = .{ .x = 0, .y = 0, .z = zfar };
    frustum_planes[@intFromEnum(Planes.FAR_FRUSTUM_PLANE)].normal.x = 0;
    frustum_planes[@intFromEnum(Planes.FAR_FRUSTUM_PLANE)].normal.y = 0;
    frustum_planes[@intFromEnum(Planes.FAR_FRUSTUM_PLANE)].normal.z = -1;
}

pub fn polygonFromTriangle(triangle: *const Triangle) Polygon {
    var polygon: Polygon = undefined;
    @memset(&polygon.vertices, .{
        .position = .{ .x = 0, .y = 0, .z = 0, .w = 0 },
        .tex_coord = .{ .u = 0, .v = 0 },
    });

    polygon.vertices[0] = triangle.vertices[0];
    polygon.vertices[1] = triangle.vertices[1];
    polygon.vertices[2] = triangle.vertices[2];
    polygon.num_vertices = 3;

    return polygon;
}

pub fn trianglesFromPolygon(polygon: *Polygon, triangles: [*]Triangle, num_triangles_after_clipping: *usize) void {
    var i: usize = 0;
    while (i < polygon.num_vertices - 2) : (i += 1) {
        const index0: usize = 0;
        const index1: usize = i + 1;
        const index2: usize = i + 2;

        triangles[i].vertices[0] = polygon.vertices[index0];
        triangles[i].vertices[1] = polygon.vertices[index1];
        triangles[i].vertices[2] = polygon.vertices[index2];
    }
    const num_vertices_poly: usize = @intCast(polygon.num_vertices);
    num_triangles_after_clipping.* = num_vertices_poly - 2;
}

fn floatLerp(a: f32, b: f32, t: f32) f32 {
    return a + (t * (b - a));
}

pub fn clip_polygon_against_plane(polygon: *Polygon, plane: Planes) void {
    const plane_point: Vector3 = frustum_planes[@intFromEnum(plane)].point;
    const plane_normal: Vector3 = frustum_planes[@intFromEnum(plane)].normal;

    var inside_vertices: [max_num_poly_vertices]Vertex = undefined;
    var num_inside_vertices: usize = 0;

    // Start the current vertex with the first polygon vertex.
    var current_vertex: *Vertex = &polygon.vertices[0];

    // Start the previous vertex with the last polygon vertex
    var previous_vertex: *Vertex = &polygon.vertices[polygon.num_vertices - 1];

    // Calculate the dot products of the current and previous vertex
    var current_dot: f32 = 0;

    const previous_vertex_vec3 = Vector.vec4ToVec3(&previous_vertex.position);
    var previous_dot: f32 = Vector.dotVec3(&Vector.subVec3(&previous_vertex_vec3, &plane_point), &plane_normal);

    while (current_vertex != &polygon.vertices[polygon.num_vertices]) {
        const current_vertex_vec3 = Vector.vec4ToVec3(&current_vertex.position);
        current_dot = Vector.dotVec3(&Vector.subVec3(&current_vertex_vec3, &plane_point), &plane_normal);

        // Changed from inside to outside or vice versa.
        if (current_dot * previous_dot < 0) {
            // find the lerp factor t.
            const t = previous_dot / (previous_dot - current_dot);

            // Calculate the intersection point I = Q1 + t(Q2 - Q1)
            var intersection_point: Vertex = undefined;
            intersection_point.position.x = floatLerp(previous_vertex.position.x, current_vertex.position.x, t);
            intersection_point.position.y = floatLerp(previous_vertex.position.y, current_vertex.position.y, t);
            intersection_point.position.z = floatLerp(previous_vertex.position.z, current_vertex.position.z, t);

            intersection_point.tex_coord.u = floatLerp(previous_vertex.tex_coord.u, current_vertex.tex_coord.u, t);
            intersection_point.tex_coord.v = floatLerp(previous_vertex.tex_coord.v, current_vertex.tex_coord.v, t);

            inside_vertices[num_inside_vertices] = current_vertex.*;
            num_inside_vertices += 1;
        }

        // Current vertex is inside the plane
        if (current_dot > 0) {
            inside_vertices[num_inside_vertices - 1] = current_vertex.*;
            num_inside_vertices += 1;
        }

        previous_dot = current_dot;
        previous_vertex = current_vertex;
    }

    for (0..@intCast(num_inside_vertices)) |i| {
        const vertex: Vertex = inside_vertices[i];
        polygon.vertices[i] = vertex;
    }
    // var i: i32 = 0;
    // while (i < num_inside_vertices) : (i += 1) {
    //     polygon.vertices[@intCast(i)] = Vertex.clone(&inside_vertices[@intCast(i)]);
    // }

    polygon.num_vertices = num_inside_vertices;
}

pub fn clipPolygon(polygon: *Polygon) void {
    clip_polygon_against_plane(polygon, Planes.LEFT_FRUSTUM_PLANE);
    clip_polygon_against_plane(polygon, Planes.RIGHT_FRUSTUM_PLANE);
    clip_polygon_against_plane(polygon, Planes.TOP_FRUSTUM_PLANE);
    clip_polygon_against_plane(polygon, Planes.BOTTOM_FRUSTUM_PLANE);
    clip_polygon_against_plane(polygon, Planes.NEAR_FRUSTUM_PLANE);
    clip_polygon_against_plane(polygon, Planes.FAR_FRUSTUM_PLANE);
}
