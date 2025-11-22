const std = @import("std");

const glfw = @import("zglfw");
const zopengl = @import("zopengl");

const gl = zopengl.bindings;

const GL_VERSION_MAJOR = 3;
const GL_VERSION_MINOR = 3;

pub fn main() !void {
    try glfw.init();
    defer glfw.terminate();

    const scr_width = 800;
    const scr_height = 600;

    glfw.windowHint(.context_version_major, GL_VERSION_MAJOR);
    glfw.windowHint(.context_version_minor, GL_VERSION_MINOR);
    glfw.windowHint(.opengl_profile, .opengl_core_profile);

    const window = try glfw.createWindow(scr_width, scr_height, "learning-zig-opengl", null);
    defer window.destroy();

    glfw.makeContextCurrent(window);
    try zopengl.loadCoreProfile(glfw.getProcAddress, GL_VERSION_MAJOR, GL_VERSION_MINOR);

    gl.viewport(0, 0, scr_width, scr_height);

    while (!glfw.windowShouldClose(window)) {
        gl.clear(gl.COLOR_BUFFER_BIT);



        glfw.swapBuffers(window);
        glfw.pollEvents();
    }
}
