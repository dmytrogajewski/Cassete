/* GLArea-based isolated shader test (works regardless of GSK renderer) */

using Gtk;
using GLib;

[CCode (cheader_filename = "GL/gl.h", cprefix = "")]
namespace GL {

    public const int GL_VERTEX_SHADER = 0x8B31;
    public const int GL_FRAGMENT_SHADER = 0x8B30;
    public const int GL_COMPILE_STATUS = 0x8B81;
    public const int GL_LINK_STATUS = 0x8B82;
    public const int GL_ARRAY_BUFFER = 0x8892;
    public const int GL_STATIC_DRAW = 0x88E4;
    public const int GL_FLOAT = 0x1406;
    public const int GL_TRIANGLE_STRIP = 0x0005;

    [CCode (cname = "glCreateShader")] public extern uint glCreateShader (uint type);
    [CCode (cname = "glShaderSource")] public extern void glShaderSource (uint shader, int count, [CCode (array_length = false)] string[] strings, int* lengths);
    [CCode (cname = "glCompileShader")] public extern void glCompileShader (uint shader);
    [CCode (cname = "glGetShaderiv")] public extern void glGetShaderiv (uint shader, uint pname, out int param);
    [CCode (cname = "glGetShaderInfoLog")] public extern void glGetShaderInfoLog (uint shader, int bufSize, out int length, [CCode (array_length = false)] char[] infoLog);
    [CCode (cname = "glCreateProgram")] public extern uint glCreateProgram ();
    [CCode (cname = "glAttachShader")] public extern void glAttachShader (uint program, uint shader);
    [CCode (cname = "glLinkProgram")] public extern void glLinkProgram (uint program);
    [CCode (cname = "glGetProgramiv")] public extern void glGetProgramiv (uint program, uint pname, out int param);
    [CCode (cname = "glGetProgramInfoLog")] public extern void glGetProgramInfoLog (uint program, int bufSize, out int length, [CCode (array_length = false)] char[] infoLog);
    [CCode (cname = "glDeleteShader")] public extern void glDeleteShader (uint shader);
    [CCode (cname = "glUseProgram")] public extern void glUseProgram (uint program);
    [CCode (cname = "glGetUniformLocation")] public extern int glGetUniformLocation (uint program, string name);
    [CCode (cname = "glUniform1f")] public extern void glUniform1f (int location, float v0);
    [CCode (cname = "glUniform2f")] public extern void glUniform2f (int location, float v0, float v1);
    [CCode (cname = "glViewport")] public extern void glViewport (int x, int y, int w, int h);
    [CCode (cname = "glGenBuffers")] public extern void glGenBuffers (int n, out uint buffer);
    [CCode (cname = "glBindBuffer")] public extern void glBindBuffer (uint target, uint buffer);
    [CCode (cname = "glBufferData")] public extern void glBufferData (uint target, long size, [CCode (array_length = false)] float[] data, uint usage);
    [CCode (cname = "glEnableVertexAttribArray")] public extern void glEnableVertexAttribArray (uint index);
    [CCode (cname = "glVertexAttribPointer")] public extern void glVertexAttribPointer (uint index, int size, uint type, bool normalized, int stride, void* pointer);
    [CCode (cname = "glDrawArrays")] public extern void glDrawArrays (uint mode, int first, int count);
}

public class GLTestArea : Gtk.GLArea {
    private const string VERT_SRC = """
#version 300 es
layout(location=0) in vec2 a_pos;
out vec2 v_uv;
void main(){
    v_uv = a_pos * 0.5 + 0.5; // map [-1,1] -> [0,1]
    gl_Position = vec4(a_pos,0.0,1.0);
}
""";

    private const string FRAG_SRC = """
#version 300 es
precision mediump float;

in vec2 v_uv;
out vec4 color;

uniform float u_time;
uniform vec2 u_resolution;

mat2 m(float a) {
    float c = cos(a);
    float s = sin(a);
    return mat2(c, -s, s, c);
}

float map(vec3 p) {
    p.xz *= m(u_time * 0.4);
    p.xy *= m(u_time * 0.3);
    vec3 q = p * 2.0 + u_time;
    return length(p + vec3(sin(u_time * 0.7))) * log(length(p) + 1.0) + sin(q.x + sin(q.z + sin(q.y))) * 0.5 - 1.0;
}

void main() {
    vec2 fragCoord = v_uv * u_resolution.xy;
    vec2 center = vec2(0.5 * (u_resolution.x / u_resolution.y), 0.5);
    vec2 p = fragCoord / u_resolution.y - center;
    p *= 0.6;
    
    vec3 cl = vec3(0.0);
    float d = 2.5;
    
    for(int i = 0; i <= 5; i++) {
        vec3 p3 = vec3(0.0, 0.0, 5.0) + normalize(vec3(p, -1.0)) * d;
        float rz = map(p3);
        float f = clamp((rz - map(p3 + 0.1)) * 0.5, -0.1, 1.0);
        vec3 l = vec3(0.1, 0.3, 0.4) + vec3(5.0, 2.5, 3.0) * f;
        cl = cl * l + smoothstep(2.5, 0.0, rz) * 0.7 * l;
        d += min(rz, 1.0);
    }
    // Intensity from Ether field
    float intensity = clamp(length(cl), 0.0, 1.0);

    // Angle-based palette: magenta -> yellow -> green -> magenta
    const float PI = 3.14159265359;
    float ang = atan(p.y, p.x);
    float t = (ang + PI) / (2.0 * PI); // [0,1]

    vec3 c_magenta = vec3(0.95, 0.15, 0.80);
    vec3 c_yellow  = vec3(1.00, 0.90, 0.15);
    vec3 c_red     = vec3(0.95, 0.20, 0.20);

    vec3 pal;
    if (t < 0.333) {
        float k = smoothstep(0.00, 0.333, t);
        pal = mix(c_magenta, c_yellow, k);
    } else if (t < 0.666) {
        float k = smoothstep(0.333, 0.666, t);
        pal = mix(c_yellow, c_red, k);
    } else {
        float k = smoothstep(0.666, 1.0, t);
        pal = mix(c_red, c_magenta, k);
    }

    // Apply palette and slight gamma for glow
    vec3 col = pal * pow(intensity, 0.85);

    // Soft vignette similar to reference
    float vign = smoothstep(1.2, 0.1, length(p));
    col *= vign;

    color = vec4(col, 1.0);
}
""";

    private uint program = 0;
    private uint vbo = 0;
    private int u_time_loc = -1;
    private int u_res_loc = -1;
    private double t0 = 0.0;
    private uint tick_id = 0;

    construct {
        set_auto_render (true);
        this.hexpand = true;
        this.vexpand = true;
        this.halign = Gtk.Align.FILL;
        this.valign = Gtk.Align.FILL;
        realize.connect (on_realize);
        render.connect (on_render);
        t0 = GLib.get_monotonic_time () / 1e6;
        map.connect (() => { if (tick_id == 0) tick_id = add_tick_callback (on_tick); });
        unmap.connect (() => { if (tick_id != 0) { remove_tick_callback (tick_id); tick_id = 0; } });
    }

    private void on_realize () {
        make_current ();
        program = build_program (VERT_SRC, FRAG_SRC);
        if (program == 0u) return;
        u_time_loc = GL.glGetUniformLocation (program, "u_time");
        u_res_loc = GL.glGetUniformLocation (program, "u_resolution");
        float[] verts = { -1f, -1f, 1f, -1f, -1f, 1f, 1f, 1f };
        GL.glGenBuffers (1, out vbo);
        GL.glBindBuffer (GL.GL_ARRAY_BUFFER, vbo);
        GL.glBufferData (GL.GL_ARRAY_BUFFER, (long)(verts.length * sizeof (float)), verts, GL.GL_STATIC_DRAW);
    }

    private bool on_render (Gdk.GLContext ctx) {
        if (program == 0u) return false;
        int w_log = get_allocated_width ();
        int h_log = get_allocated_height ();
        int scale = this.get_scale_factor ();
        int w_fb = w_log * scale;
        int h_fb = h_log * scale;
        GL.glViewport (0, 0, w_fb, h_fb);
        GL.glUseProgram (program);
        if (u_time_loc >= 0) GL.glUniform1f (u_time_loc, (float)(((GLib.get_monotonic_time () / 1e6) - t0) * 0.5));
        if (u_res_loc >= 0) GL.glUniform2f (u_res_loc, (float)w_log, (float)h_log);
        GL.glBindBuffer (GL.GL_ARRAY_BUFFER, vbo);
        GL.glEnableVertexAttribArray (0u);
        GL.glVertexAttribPointer (0u, 2, GL.GL_FLOAT, false, 0, null);
        GL.glDrawArrays (GL.GL_TRIANGLE_STRIP, 0, 4);
        return true;
    }

    private bool on_tick (Gtk.Widget w, Gdk.FrameClock clock) {
        // Schedule a new frame; GLArea will call render
        this.queue_render ();
        return true; // continue ticking
    }

    private uint build_program (string vs_src, string fs_src) {
        var vs = compile_shader (GL.GL_VERTEX_SHADER, vs_src);
        var fs = compile_shader (GL.GL_FRAGMENT_SHADER, fs_src);
        if (vs == 0u || fs == 0u) return 0u;
        var prog = GL.glCreateProgram ();
        GL.glAttachShader (prog, vs);
        GL.glAttachShader (prog, fs);
        GL.glLinkProgram (prog);
        int ok; GL.glGetProgramiv (prog, GL.GL_LINK_STATUS, out ok);
        if (ok == 0) {
            char[] log = new char[1024]; int l;
            GL.glGetProgramInfoLog (prog, log.length, out l, log);
            stderr.printf ("Program link error: %s\n", (string)log);
            return 0u;
        }
        GL.glDeleteShader (vs); GL.glDeleteShader (fs);
        return prog;
    }

    private uint compile_shader (int type, string src) {
        var sh = GL.glCreateShader ((uint)type);
        string[] arr = { src }; GL.glShaderSource (sh, 1, arr, null);
        GL.glCompileShader (sh); int ok; GL.glGetShaderiv (sh, GL.GL_COMPILE_STATUS, out ok);
        if (ok == 0) {
            char[] log = new char[1024]; int l;
            GL.glGetShaderInfoLog (sh, log.length, out l, log);
            stderr.printf ("Shader compile error: %s\n", (string)log);
            return 0u;
        }
        return sh;
    }
}

public int main (string[] args) {
    var app = new Gtk.Application ("com.test.shader", 0);
    app.activate.connect (() => {
        var win = app.get_active_window ();
        if (win == null) {
            win = new Gtk.ApplicationWindow (app);
            win.set_default_size (800, 600);
            win.title = "GLArea Shader Test";
            win.set_child (new GLTestArea ());
        }
        win.present ();
    });
    return app.run (args);
}

