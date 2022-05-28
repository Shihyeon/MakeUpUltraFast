/* Exits */
out vec4 outColor0;

#include "/lib/config.glsl"

#if defined THE_END
  #include "/lib/color_utils_end.glsl"
#elif defined NETHER
  #include "/lib/color_utils_nether.glsl"
#endif

/* Config, uniforms, ins, outs */
uniform sampler2D gtexture;
uniform int isEyeInWater;
uniform float nightVision;
uniform float rainStrength;
uniform float light_mix;
uniform float pixel_size_x;
uniform float pixel_size_y;
uniform sampler2D gaux4;
uniform float alphaTestRef;

#if defined GBUFFER_ENTITIES
  uniform int entityId;
  uniform vec4 entityColor;
#endif

#ifdef NETHER
  uniform vec3 fogColor;
#endif

#if defined SHADOW_CASTING
  uniform int frame_mod;
  uniform sampler2DShadow shadowtex1;
  #if defined COLORED_SHADOW
    uniform sampler2DShadow shadowtex0;
    uniform sampler2D shadowcolor0;
  #endif
#endif

in vec2 texcoord;
in vec4 tint_color;
in float frog_adjust;
in vec3 direct_light_color;
in vec3 candle_color;
in float direct_light_strenght;
in vec3 omni_light;
in float var_fog_frag_coord;

#if defined GBUFFER_TERRAIN || defined GBUFFER_HAND
  in float emmisive_type;
#endif

#ifdef FOLIAGE_V
  in float is_foliage;
#endif

#if defined SHADOW_CASTING && !defined NETHER
  in vec3 shadow_pos;
  in float shadow_diffuse;
#endif

#if defined SHADOW_CASTING && !defined NETHER
  #include "/lib/dither.glsl"
  #include "/lib/shadow_frag.glsl"
#endif

#include "/lib/luma.glsl"









uniform int worldTime;
uniform vec3 moonPosition;
uniform vec3 sunPosition;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferProjection;

in vec2 lmcoord_alt;
flat in vec3 material_normal;
in vec4 position2;
in vec3 tangent;
in vec3 binormal;

#include "/lib/projection_utils.glsl"

float material_gloss(vec3 fragpos) {
  vec3 astro_pos = worldTime > 12900 ? moonPosition : sunPosition;
  float astro_vector =
    max(dot(normalize(fragpos), normalize(astro_pos)), 0.0);

  return clamp(
      // smoothstep(0.875, 1.0, pow(astro_vector, 0.5)) *
      mix(0.0, 1.0, pow(clamp(astro_vector * 2.0 - 1.0, 0.0, 1.0), 7.0)) *
      clamp(lmcoord_alt.y, 0.0, 1.0) *
      (1.0 - rainStrength),
      0.0,
      1.0
    ) * 2.0;
}
  
vec3 get_mat_normal(vec3 bump) {
  float NdotE = abs(dot(material_normal, normalize(position2.xyz)));

  bump *= vec3(NdotE) + vec3(0.0, 0.0, 1.0 - NdotE);

  mat3 tbn_matrix = mat3(
    tangent.x, binormal.x, material_normal.x,
    tangent.y, binormal.y, material_normal.y,
    tangent.z, binormal.z, material_normal.z
    );

  return normalize(bump * tbn_matrix);
}






void main() {
  vec3 fragpos =
    to_screen_space(
      vec3(gl_FragCoord.xy * vec2(pixel_size_x, pixel_size_y), gl_FragCoord.z)
      );
  vec3 flat_normal = get_mat_normal(vec3(0.0, 0.0, 1.0));




  vec3 direct_test = direct_light_color;
  // Toma el color puro del bloque
  #if defined GBUFFER_ENTITIES
    #if BLACK_ENTITY_FIX == 1
      vec4 block_color = texture(gtexture, texcoord);
      if (block_color.a < 0.1 && entityId != 10101) {   // Black entities bug workaround
        discard;
      }
      block_color *= tint_color;
    #else
      vec4 block_color = texture(gtexture, texcoord) * tint_color;
    #endif
  #else
    vec4 block_color = texture(gtexture, texcoord) * tint_color;
  #endif

  vec3 final_candle_color = candle_color;
  #if defined GBUFFER_TERRAIN || defined GBUFFER_HAND
    float candle_luma = 1.0;
    if (emmisive_type > 0.5) {
      candle_luma = luma(block_color.rgb);
      final_candle_color *= candle_luma * 1.5;
    }
  #endif
  
  #ifdef GBUFFER_WEATHER
    block_color.a *= .5;
  #endif

  #if defined GBUFFER_ENTITIES
    // Thunderbolt render
    if (entityId == 10101){
      block_color.a = 1.0;
    }
  #endif

  if(block_color.a < alphaTestRef) discard;  // Full transparency

  #if defined SHADOW_CASTING && !defined NETHER
    #if defined COLORED_SHADOW
      vec3 shadow_c = get_colored_shadow(shadow_pos);
      shadow_c = mix(shadow_c, vec3(1.0), shadow_diffuse);
    #else
      float shadow_c = get_shadow(shadow_pos);
      shadow_c = mix(shadow_c, 1.0, shadow_diffuse);
    #endif
  #else
    float shadow_c = abs((light_mix * 2.0) - 1.0);
  #endif

  #if defined GBUFFER_BEACONBEAM
    block_color.rgb *= 1.5;
  #else
    // vec3 real_light =
    //   omni_light +
    //   (direct_light_strenght * shadow_c * direct_light_color) * (1.0 - (rainStrength * 0.75)) +
    //   final_candle_color;


    vec3 material_gloss_color = direct_light_color * material_gloss(reflect(normalize(fragpos), flat_normal));
    vec3 real_light =
      omni_light +
      (direct_light_strenght * shadow_c * direct_light_color + material_gloss_color * shadow_c) * (1.0 - (rainStrength * 0.75)) +
      final_candle_color;

    // vec3 real_light = material_gloss_color;

    block_color.rgb *= mix(real_light, vec3(1.0), nightVision * .125);
  #endif

  #if defined GBUFFER_ENTITIES
    if (entityId == 10101) {
      // Thunderbolt render
      block_color = vec4(1.0, 1.0, 1.0, 0.5);
    } else {
      block_color.rgb = mix(block_color.rgb, entityColor.rgb, entityColor.a * .75);
    }
  #endif

  #include "/src/finalcolor.glsl"
  #include "/src/writebuffers.glsl"
}
