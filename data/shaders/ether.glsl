#version 300 es

precision mediump float;

in vec2 gsk_uv;
out vec4 frag_color;

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
    // Convert UV (0-1) to pixel coordinates, then to centered shadertoy format
    vec2 fragCoord = gsk_uv * u_resolution.xy;
    // Compute true center in the scaled coordinate space
    vec2 center = vec2(0.5 * (u_resolution.x / u_resolution.y), 0.5);
    vec2 p = fragCoord / u_resolution.y - center;
    
    // Zoom in to make the blob larger
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
    
    frag_color = vec4(cl, 1.0);
}


