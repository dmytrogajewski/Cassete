#include "vibe-canvas-helper.h"
#include <string.h>

GBytes* 
gsk_gl_shader_format_args_wrapper (GskGLShader *shader, 
                                   float time, 
                                   float res_x, 
                                   float res_y)
{
    // Get the expected args size from the shader
    gsize args_size = gsk_gl_shader_get_args_size (shader);
    
    if (args_size == 0) {
        g_warning ("Shader args size is 0");
        return g_bytes_new (NULL, 0);
    }
    
    // Allocate and zero-initialize buffer for uniforms
    uint8_t* uniforms = g_malloc0 (args_size);
    
    // Find uniform indices by name
    int time_idx = gsk_gl_shader_find_uniform_by_name (shader, "u_time");
    int res_idx = gsk_gl_shader_find_uniform_by_name (shader, "u_resolution");
    
    if (time_idx < 0) {
        g_warning ("Uniform 'u_time' not found in shader");
    } else {
        int offset = gsk_gl_shader_get_uniform_offset (shader, time_idx);
        if (offset >= 0 && offset + sizeof(float) <= (int)args_size) {
            memcpy (uniforms + offset, &time, sizeof(float));
        } else {
            g_warning ("Invalid offset for u_time: %d (args_size: %zu)", offset, args_size);
        }
    }
    
    if (res_idx < 0) {
        g_warning ("Uniform 'u_resolution' not found in shader");
    } else {
        int offset = gsk_gl_shader_get_uniform_offset (shader, res_idx);
        if (offset >= 0 && offset + 2 * sizeof(float) <= (int)args_size) {
            float res[2] = { res_x, res_y };
            memcpy (uniforms + offset, res, 2 * sizeof(float));
        } else {
            g_warning ("Invalid offset for u_resolution: %d (args_size: %zu)", offset, args_size);
        }
    }
    
    GBytes* bytes = g_bytes_new_take (uniforms, args_size);
    return bytes;
}

GskRenderNode*
gsk_gl_shader_node_new_simple (GskGLShader *shader,
                               float x,
                               float y,
                               float width,
                               float height,
                               GBytes *args)
{
    graphene_rect_t rect;
    graphene_rect_init (&rect, x, y, width, height);

    // No children/textures
    return gsk_gl_shader_node_new (shader, &rect, args, NULL, 0);
}

