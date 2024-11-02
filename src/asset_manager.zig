pub const AssetManager = @This();

const std = @import("std");
const vector = @import("vector.zig");
const Vector3 = vector.Vector3;
const Vector4 = vector.Vector4;
const Vertex = @import("vertex.zig");
const Face = @import("triangle.zig").Face;
const Mesh = @import("mesh.zig");
const Model = @import("model.zig");
const raylib = @import("raylib");
const Color = @import("color.zig").Color;
const Texture = @import("texture.zig");
const TextureCoords = @import("texturecoords.zig");

arena: std.heap.ArenaAllocator,
allocator: std.mem.Allocator,
file_allocator: std.mem.Allocator,

pub fn init(allocator: std.mem.Allocator) AssetManager {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const file_allocator = arena.allocator();

    return .{
        .arena = arena,
        .file_allocator = file_allocator,
        .allocator = allocator,
    };
}

pub fn deinit(self: *AssetManager) void {
    self.arena.deinit();
}

pub fn loadTexture(self: *AssetManager, path: [*:0]const u8) !Texture {
    const allocator = self.arena.allocator();

    // Load texture data in cpu ram.
    const image: raylib.Image = raylib.loadImage(path);
    const image_pixels = try raylib.loadImageColors(image);
    defer raylib.unloadImage(image);

    const image_height: usize = @intCast(image.height);
    const image_width: usize = @intCast(image.width);

    const texture = try Texture.init(allocator, image_width, image_height);

    var index: usize = 0;
    var curr_color: raylib.Color = undefined;
    for (0..image_height) |y| {
        for (0..image_width) |x| {
            index = y * image_height + x;
            curr_color = image_pixels[index];

            texture.pixels[index].r = curr_color.r;
            texture.pixels[index].g = curr_color.g;
            texture.pixels[index].b = curr_color.b;
            texture.pixels[index].a = curr_color.a;
        }
    }

    return texture;
}

pub fn loadModel(self: *AssetManager, mesh_path: [*:0]const u8, texture_path: [*:0]const u8) !Model {
    const mesh = try self.loadObj(mesh_path);
    const texture = try self.loadTexture(texture_path);

    return .{
        .mesh = mesh,
        .texture = texture,
    };
}

pub fn loadObj(self: *AssetManager, path: [*:0]const u8) !Mesh {
    var path_buffer: [std.fs.max_path_bytes:0]u8 = undefined;
    _ = try std.fs.realpathZ(path, &path_buffer);

    var file = try std.fs.openFileAbsoluteZ(&path_buffer, .{ .mode = .read_only });
    defer file.close();

    var buffered = std.io.bufferedReader(file.reader());
    var reader = buffered.reader();

    var line_buffer: [1024]u8 = undefined;

    const allocator = self.arena.allocator();
    var points = std.ArrayList(Vector4).init(allocator);
    var normals = std.ArrayList(Vector3).init(allocator);
    var faces = std.ArrayList(ObjFace).init(allocator);
    var texture_coords = std.ArrayList(TextureCoords).init(allocator);

    while (try reader.readUntilDelimiterOrEof(&line_buffer, '\n')) |line| {
        if (line.len <= 3) {
            continue;
        } else if (std.mem.eql(u8, line[0..2], "v ")) {
            const point: Vector4 = parseVector(line);
            try points.append(point);
        } else if (std.mem.eql(u8, line[0..2], "f ")) {
            const face: ObjFace = try parseFace(line);
            try faces.append(face);
        } else if (std.mem.eql(u8, line[0..3], "vt ")) {
            const texture_coord = parseTextureCoord(line);
            try texture_coords.append(texture_coord);
        } else if (std.mem.eql(u8, line[0..3], "vn ")) {
            const normal = parseNormal(line);
            try normals.append(normal);
        }
    }

    var vertices = std.ArrayList(Vertex).init(allocator);
    var indices = std.ArrayList(usize).init(allocator);

    var face_count: usize = 0;
    for (faces.items) |face| {
        var vertex1: Vertex = undefined;
        var vertex2: Vertex = undefined;
        var vertex3: Vertex = undefined;

        vertex1.position = points.items[face.vertex_indices[0] - 1];
        vertex2.position = points.items[face.vertex_indices[1] - 1];
        vertex3.position = points.items[face.vertex_indices[2] - 1];

        vertex1.normal = normals.items[face.normal_indices[0] - 1];
        vertex2.normal = normals.items[face.normal_indices[1] - 1];
        vertex3.normal = normals.items[face.normal_indices[2] - 1];

        vertex1.tex_coord = texture_coords.items[face.texture_indices[0] - 1];
        vertex2.tex_coord = texture_coords.items[face.texture_indices[1] - 1];
        vertex3.tex_coord = texture_coords.items[face.texture_indices[2] - 1];

        vertex1.color = Color.dark_gray;
        vertex2.color = Color.dark_gray;
        vertex3.color = Color.dark_gray;

        try vertices.append(vertex1);
        try indices.append(face_count);

        try vertices.append(vertex2);
        try indices.append(face_count + 1);

        try vertices.append(vertex3);
        try indices.append(face_count + 2);

        face_count += 3;
    }

    const mesh: Mesh = Mesh.init(vertices);
    return mesh;
}

// TODO: Move obj parsing to an obj parser.
fn parseVector(line: []u8) Vector4 {
    var vertex_floats: [3]f32 = undefined;
    var it = std.mem.splitAny(u8, line, " ");
    var i: usize = 0;

    while (it.next()) |part| {
        const parsed_float = std.fmt.parseFloat(f32, part) catch {
            continue;
        };
        vertex_floats[i] = parsed_float;
        i += 1;
    }

    return .{
        .x = vertex_floats[0],
        .y = vertex_floats[1],
        .z = vertex_floats[2],
        .w = 1.0,
    };
}

fn parseTextureCoord(line: []u8) TextureCoords {
    var vertex_floats: [2]f32 = undefined;
    var it = std.mem.splitAny(u8, line, " ");
    var i: usize = 0;

    while (it.next()) |part| {
        const parsed_float = std.fmt.parseFloat(f32, part) catch {
            continue;
        };
        vertex_floats[i] = parsed_float;
        i += 1;
    }

    return .{
        .u = vertex_floats[0],
        .v = vertex_floats[1],
    };
}

fn parseNormal(line: []u8) Vector3 {
    var vertex_floats: [3]f32 = undefined;
    var it = std.mem.splitAny(u8, line, " ");
    var i: usize = 0;

    while (it.next()) |part| {
        const parsed_float = std.fmt.parseFloat(f32, part) catch {
            continue;
        };
        vertex_floats[i] = parsed_float;
        i += 1;
    }

    return .{
        .x = vertex_floats[0],
        .y = vertex_floats[1],
        .z = vertex_floats[2],
    };
}

fn parseFace(line: []u8) !ObjFace {
    var it = std.mem.splitAny(u8, line, " ");

    // Skip the f part of the line
    _ = it.next();

    // Parse first set of vertex, text_coord, normal indices.
    var indices_1 = std.mem.splitAny(u8, it.next().?, "/");
    const vertex_index_1 = try std.fmt.parseInt(usize, indices_1.next().?, 10);
    const texture_coord_1 = try std.fmt.parseInt(usize, indices_1.next().?, 10);
    const normal_index_1 = try std.fmt.parseInt(usize, indices_1.next().?, 10);

    // Parse second set of vertex, text_coord, normal indices.
    var indices_2 = std.mem.splitAny(u8, it.next().?, "/");
    const vertex_index_2 = try std.fmt.parseInt(usize, indices_2.next().?, 10);
    const texture_coord_2 = try std.fmt.parseInt(usize, indices_2.next().?, 10);
    const normal_index_2 = try std.fmt.parseInt(usize, indices_2.next().?, 10);

    // Parse third set of vertex, text_coord, normal indices.
    var indices_3 = std.mem.splitAny(u8, it.next().?, "/");
    const vertex_index_3 = try std.fmt.parseInt(usize, indices_3.next().?, 10);
    const texture_coord_3 = try std.fmt.parseInt(usize, indices_3.next().?, 10);
    const normal_index_3 = try std.fmt.parseInt(usize, indices_3.next().?, 10);

    return .{
        .vertex_indices = [_]usize{ vertex_index_1, vertex_index_2, vertex_index_3 },
        .texture_indices = [_]usize{ texture_coord_1, texture_coord_2, texture_coord_3 },
        .normal_indices = [_]usize{ normal_index_1, normal_index_2, normal_index_3 },
    };
}

const ObjFace = struct {
    vertex_indices: [3]usize,
    texture_indices: [3]usize,
    normal_indices: [3]usize,
};
