const std = @import("std");
const Vector3 = @import("vector.zig").Vector3;
const Face = @import("triangl.zig").Face;
const Mesh = @import("mesh.zig").Mesh;

pub const AssetManager = struct {
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

    pub fn loadObj(self: *AssetManager) !Mesh {
        var path_buffer: [std.fs.max_path_bytes:0]u8 = undefined;
        _ = try std.fs.realpath("./assets/f22.obj", &path_buffer);

        var file = try std.fs.openFileAbsoluteZ(&path_buffer, .{ .mode = .read_only });
        defer file.close();

        var buffered = std.io.bufferedReader(file.reader());
        var reader = buffered.reader();

        var line_buffer: [1024]u8 = undefined;

        const allocator = self.arena.allocator();
        var vertices = std.ArrayList(Vector3).init(allocator);
        var faces = std.ArrayList(Face).init(allocator);

        while (try reader.readUntilDelimiterOrEof(&line_buffer, '\n')) |line| {
            if (line.len <= 3) {
                continue;
            } else if (std.mem.eql(u8, line[0..2], "v ")) {
                const vertex: Vector3 = parseVector(line);
                try vertices.append(vertex);
            } else if (std.mem.eql(u8, line[0..2], "f ")) {
                const face: Face = parseFace(line);
                try faces.append(face);
            }
        }

        const mesh: Mesh = Mesh.init(vertices, faces);
        return mesh;
    }

    fn parseVector(line: []u8) Vector3 {
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

    fn parseFace(line: []u8) Face {
        var face_indices: [3]u16 = undefined;
        var it = std.mem.splitAny(u8, line, " ");
        var i: usize = 0;

        while (it.next()) |part| {
            if (std.mem.eql(u8, part, "f ")) {
                continue;
            }

            var indices = std.mem.splitAny(u8, part, "/");
            const vertex_index = std.fmt.parseInt(u16, indices.first(), 10) catch {
                continue;
            };

            face_indices[i] = vertex_index;
            i += 1;
        }

        return .{
            .a = face_indices[0],
            .b = face_indices[1],
            .c = face_indices[2],
        };
    }
};
