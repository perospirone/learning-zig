const std = @import("std");
const builtin = @import("builtin");

const Player = struct {
    name: []const u8,
    age: u8,

    fn walk(self: Player, direction: []const u8, quantity: u8) void {
        std.debug.print("{s} walking to {s} steps: {d}\n", .{ self.name, direction, quantity });
    }

    fn info(self: Player) void {
        std.debug.print("name: {s} age: {d}\n", .{ self.name, self.age });
    }

    fn birthday(self: *Player) void {
        std.debug.print("happy birthday {s}\n", .{self.name});
        self.age += 1;
    }

    fn change_name(self: *Player, newname: []const u8) void {
        self.name = newname;
    }
};

pub fn main() !void {
    var daniel = Player{
        .name = "Daniel",
        .age = 20,
    };

    daniel.walk("north", 20);
    daniel.info();

    daniel.birthday();

    daniel.info();

    daniel.change_name("Daniel de Sá");

    const allocator = std.heap.page_allocator;

    const bytes = try allocator.alloc(u8, 100);
    defer allocator.free(bytes);
}

test "fuzz example" {
    const Context = struct {
        fn testOne(context: @This(), input: []const u8) anyerror!void {
            _ = context;
            // Try passing `--fuzz` to `zig build test` and see if it manages to fail this test case!
            try std.testing.expect(!std.mem.eql(u8, "canyoufindme", input));
        }
    };
    try std.testing.fuzz(Context{}, Context.testOne, .{});
}
