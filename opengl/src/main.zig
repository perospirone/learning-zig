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

    const vertices = &[_]f32{ -0.5, -0.5, 0.5, -0.5, 0.0, 0.5 };

    var vao: u32 = undefined;
    gl.genVertexArrays(1, &vao);
    gl.bindVertexArray(vao);

    var vbo: u32 = undefined;
    gl.genBuffers(1, &vbo);
    gl.bindBuffer(gl.ARRAY_BUFFER, vbo);

    gl.bufferData(
        gl.ARRAY_BUFFER,
        vertices.len * @sizeOf(f32),
        vertices.ptr,
        gl.STATIC_DRAW,
    );

    gl.vertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, 2 * @sizeOf(f32), null);
    gl.enableVertexAttribArray(0);

    const vertex_shader_src = @embedFile("vertex.glsl");
    const vertex_shader = gl.createShader(gl.VERTEX_SHADER);

    gl.shaderSource(vertex_shader, 1, &vertex_shader_src.ptr, null);
    gl.compileShader(vertex_shader);

    const frag_shader_src = @embedFile("./frag.glsl");

    const fragment_shader = gl.createShader(gl.FRAGMENT_SHADER);
    gl.shaderSource(fragment_shader, 1, &frag_shader_src.ptr, null);
    gl.compileShader(fragment_shader);

    const shader_program = gl.createProgram();
    gl.attachShader(shader_program, vertex_shader);
    gl.attachShader(shader_program, fragment_shader);
    gl.linkProgram(shader_program);

    // verify
    var success: i32 = 0;
    gl.getShaderiv(vertex_shader, gl.COMPILE_STATUS, &success);
    if (success == 0) {
        const log_len: i32 = 512;
        var info_log: [512]u8 = undefined;
        gl.getShaderInfoLog(vertex_shader, log_len, null, &info_log[0]);
        std.debug.print("Vertex shader compile error: {s}\n", .{info_log});
        return error.CompileFailed;
    }

    gl.deleteShader(vertex_shader);
    gl.deleteShader(fragment_shader);

    while (!glfw.windowShouldClose(window)) {
        gl.clearColor(0.1, 0.1, 0.1, 1.0);
        gl.clear(gl.COLOR_BUFFER_BIT);

        gl.useProgram(shader_program);
        gl.bindVertexArray(vao);
        gl.drawArrays(gl.TRIANGLES, 0, 3);

        // updates
        glfw.swapBuffers(window);
        glfw.pollEvents();
    }
}
