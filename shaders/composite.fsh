#version 120
/* MakeUp Ultra Fast - composite.fsh
Render: Ambient occlusion

Javier Garduño - GNU Lesser General Public License v3.0
*/

#define NO_SHADOWS

#include "/lib/config.glsl"

// 'Global' constants from system
uniform sampler2D colortex0;
uniform ivec2 eyeBrightnessSmooth;
uniform int isEyeInWater;
uniform vec3 skyColor;
uniform sampler2D depthtex0;
uniform float far;
uniform float near;

#if AO == 1
  uniform float aspectRatio;
  uniform mat4 gbufferProjection;
  uniform float frameTimeCounter;
#endif

// Varyings (per thread shared variables)
varying vec2 texcoord;

#include "/lib/color_utils.glsl"
#include "/lib/depth.glsl"

#if AO == 1
  #include "/lib/dither.glsl"
  #include "/lib/ao.glsl"
#endif

void main() {
  vec4 block_color = texture2D(colortex0, texcoord);

  #if AO == 1
    // AO distance attenuation
    float d = texture2D(depthtex0, texcoord).r;
    float ao_att = sqrt(ld(d));
    float final_ao = mix(dbao(), 1.0, ao_att);
    block_color *= final_ao;
    // block_color = vec4(vec3(final_ao), 1.0);
  #endif

  // Niebla bajo el agua
  #if AO == 0
    float d = texture2D(depthtex0, texcoord).r;
  #endif
  if (isEyeInWater == 1) {
    block_color.rgb = mix(
      block_color.rgb,
      skyColor * .5 * ((eyeBrightnessSmooth.y * .8 + 48) / 240.0),
      sqrt(ld(d))
      );
  } else if (isEyeInWater == 2) {
    d = texture2D(depthtex0, texcoord).r;
    block_color = mix(
      block_color,
      vec4(1.0, .1, 0.0, 1.0),
      sqrt(ld(d))
      );
  }

  gl_FragData[2] = block_color;
}
