#include "/lib/config.glsl"

/* Config, uniforms, ins, outs */
uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;  // TODO
uniform mat4 gbufferModelViewInverse;

varying vec2 texcoord;
varying vec4 tint_color;

#if AA_TYPE > 0
  #include "/src/taa_offset.glsl"
#endif

void main() {
  #include "/src/basiccoords_vertex.glsl"
  #include "/src/position_vertex.glsl"

  tint_color = gl_Color;
}
