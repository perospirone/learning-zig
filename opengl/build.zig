const std = @import("std");

pub fn build(b: *std.Build) void {
    // these 2 attributes are useful to limit target and optimizations, in this moment i don't want limitations
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "learning-zig-opengl",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    // setting dependencies
    const zglfw = b.dependency("zglfw", .{.target = target});
    const zopengl = b.dependency("zopengl", .{});
    const zmath = b.dependency("zmath", .{});

    exe.root_module.addImport("zglfw", zglfw.module("root"));
    exe.root_module.addImport("zopengl", zopengl.module("root"));
    exe.root_module.addImport("zmath", zmath.module("root"));

    //if (target.result.os.tag != .emscripten) {
        //exe.linkLibrary(zglfw.artifact("glfw"));
    //} for some reason chatgpt are saying to do this linkSystemLibrary instead only link library, i see this later
    exe.linkSystemLibrary("glfw");
    exe.linkSystemLibrary("dl");
    exe.linkSystemLibrary("pthread");
    exe.linkSystemLibrary("X11");
    exe.linkSystemLibrary("Xcursor");
    exe.linkSystemLibrary("Xi");
    exe.linkSystemLibrary("Xrandr");
    exe.linkSystemLibrary("Xinerama");

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
}
