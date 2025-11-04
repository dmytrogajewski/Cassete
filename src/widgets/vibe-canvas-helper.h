#ifndef VIBE_CANVAS_HELPER_H
#define VIBE_CANVAS_HELPER_H

#include <glib.h>
#include <gsk/gsk.h>
#include <stdio.h>

GBytes* gsk_gl_shader_format_args_wrapper (GskGLShader *shader, 
                                            float time, 
                                            float res_x, 
                                            float res_y);

void debug_shader_uniforms (GskGLShader *shader);

// Create a GL shader render node without children and return it
GskRenderNode* gsk_gl_shader_node_new_simple (GskGLShader *shader,
                                              float x,
                                              float y,
                                              float width,
                                              float height,
                                              GBytes *args);

#endif

