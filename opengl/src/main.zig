const std = @import("std");

const glfw = @import("zglfw");
const zopengl = @import("zopengl");
const zmath = @import("zmath");

const gl = zopengl.bindings;

const GL_VERSION_MAJOR = 3;
const GL_VERSION_MINOR = 3;

const Camera = struct {
    yaw: f32,
    pitch: f32,
    speed: f32,
    sensitivity: f32,
    zoom: f32,

    position: zmath.Vec, // where you are
    direction: zmath.Vec, // where you are looking
    up: zmath.Vec, // waht is upward for the camera
};

pub fn main() !void {
    try glfw.init();
    defer glfw.terminate();

    const scr_width = 800;
    const scr_height = 600;

    glfw.windowHint(.context_version_major, GL_VERSION_MAJOR);
    glfw.windowHint(.context_version_minor, GL_VERSION_MINOR);
    glfw.windowHint(.opengl_profile, .opengl_core_profile);

    const window = try glfw.createWindow(scr_width, scr_height, "zig-opengl-floatingwindow", null);
    defer window.destroy();

    glfw.makeContextCurrent(window);
    try zopengl.loadCoreProfile(glfw.getProcAddress, GL_VERSION_MAJOR, GL_VERSION_MINOR);

    gl.viewport(0, 0, scr_width, scr_height);

    //const vertices = &[_]f32{ -0.5, -0.5, 0.5, -0.5, 0.0, 0.5 };

    const vertices = &[_]f32{
        // Front face (z = 0.5)
        -0.5, -0.5, 0.5, // v0
        0.5, -0.5, 0.5, // v1
        0.5, 0.5, 0.5, // v2
        -0.5, 0.5, 0.5, // v3

        // Back face (z = -0.5)
        -0.5, -0.5, -0.5, // v4
        0.5, -0.5, -0.5, // v5
        0.5, 0.5, -0.5, // v6
        -0.5, 0.5, -0.5, // v7

        // Left face (x = -0.5)
        -0.5, -0.5, -0.5, // v8
        -0.5, 0.5, -0.5, // v9
        -0.5, 0.5, 0.5, // v10
        -0.5, -0.5, 0.5, // v11

        // Right face (x = 0.5)
        0.5, -0.5, -0.5, // v12
        0.5, 0.5, -0.5, // v13
        0.5, 0.5, 0.5, // v14
        0.5, -0.5, 0.5, // v15

        // Top face (y = 0.5)
        -0.5, 0.5, -0.5, // v16
        0.5, 0.5, -0.5, // v17
        0.5, 0.5, 0.5, // v18
        -0.5, 0.5, 0.5, // v19

        // Bottom face (y = -0.5)
        -0.5, -0.5, -0.5, // v20
        0.5, -0.5, -0.5, // v21
        0.5, -0.5, 0.5, // v22
        -0.5, -0.5, 0.5, // v23
    };

    const indices = &[_]u32{
        // Front
        0,  1,  2,
        0,  2,  3,
        // Back
        4,  5,  6,
        4,  6,  7,
        // Left
        8,  9,  10,
        8,  10, 11,
        // Right
        12, 13, 14,
        12, 14, 15,
        // Top
        16, 17, 18,
        16, 18, 19,
        // Bottom
        20, 21, 22,
        20, 22, 23,
    };

    var vao: u32 = undefined;
    gl.genVertexArrays(1, &vao);
    gl.bindVertexArray(vao);

    var ebo: u32 = undefined;
    gl.genBuffers(1, &ebo);
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo);
    gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, indices.len * @sizeOf(u32), indices.ptr, gl.STATIC_DRAW);

    var vbo: u32 = undefined;
    gl.genBuffers(1, &vbo);
    gl.bindBuffer(gl.ARRAY_BUFFER, vbo);

    gl.bufferData(
        gl.ARRAY_BUFFER,
        vertices.len * @sizeOf(f32),
        vertices.ptr,
        gl.STATIC_DRAW,
    );

    gl.vertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * @sizeOf(f32), null);
    gl.enableVertexAttribArray(0);

    // TODO: hot reload shaders
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


    const cam = Camera{
        .yaw = -90.0,
        .pitch = 0.0,
        .speed = 4.5,
        .sensitivity = 0.1,
        .zoom = 45.0,
        .position = zmath.loadArr3([_]f32{0.0, 0.0, 3.0}),
        .direction = zmath.loadArr3([_]f32{0.0, 0.0, -1.0}),
        .up = zmath.loadArr3([_]f32{0.0, 1.0, 0.0}),
    };

    const view = zmath.lookAtRh(cam.position, cam.position + cam.direction, cam.up);
    const projection = zmath.perspectiveFovRh(cam.zoom, scr_width/scr_height, 0.1, 100.0);


    gl.enable(gl.DEPTH_TEST);

    while (!glfw.windowShouldClose(window)) {
        gl.clearColor(0.1, 0.1, 0.1, 1.0);
        gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

        gl.useProgram(shader_program);
        gl.bindVertexArray(vao);
        gl.drawElements(gl.TRIANGLES, 36, gl.UNSIGNED_INT, null);

        // changing the color using uniforms
        const color: [3]f32 = .{ 1.0, 1.0, 0.0 }; // yellow
        const color_location = gl.getUniformLocation(shader_program, "uColor");
        gl.uniform3fv(color_location, 1, &color[0]);

        const view_loc = gl.getUniformLocation(shader_program, "uView");
        gl.uniformMatrix4fv(view_loc, 1, gl.FALSE, @ptrCast(&view));

        const proj_loc = gl.getUniformLocation(shader_program, "uProjection");
        gl.uniformMatrix4fv(proj_loc, 1, gl.FALSE, @ptrCast(&projection));

        // updates
        glfw.swapBuffers(window);
        glfw.pollEvents();
    }
}

