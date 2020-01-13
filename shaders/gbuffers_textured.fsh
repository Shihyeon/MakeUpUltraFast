#version 120
/* MakeUp Ultra Fast - gbuffers_textured.fsh
Render: Particles

Javier Garduño - GNU Lesser General Public License v3.0
*/

#define REFLECTION 1 // [0 1] Activate reflection
#define REFRACTION 1 // [0 1] Activate refraction

#include "/lib/globals.glsl"

// Varyings (per thread shared variables)
varying vec4 texcoord;
varying vec4 lmcoord;
varying vec4 tint_color;
varying vec3 normal;
varying vec3 sun_vec;
varying vec3 moon_vec;
varying float translucent;
varying float emissive;
varying float iswater;

// 'Global' constants from system
uniform int worldTime;
uniform sampler2D texture;
uniform int isEyeInWater;
uniform int entityId;
uniform float nightVision;
uniform float rainStrength;
uniform float wetness;
uniform float far;
uniform vec3 skyColor;

#include "/lib/color_utils.glsl"

void main() {
  // Custom light (lmcoord.x: candle, lmcoord.y: ambient) ----
  vec2 illumination = lmcoord.xy;
  // Tomamos el color de ambiente con base a la hora
  float current_hour = worldTime / 1000.0;
  vec3 ambient_currentlight =
    mix(
      ambient_baselight[int(floor(current_hour))],
      ambient_baselight[int(ceil(current_hour))],
      fract(current_hour)
    ) * ambient_multiplier;

  illumination.y *= illumination.y * illumination.y;  // Non-linear decay
  illumination.y = (illumination.y * .99) + .01;  // Avoid absolute dark

  // Ajuste de intensidad luminosa bajo el agua
  if (isEyeInWater == 1.0) {
    illumination.y = (illumination.y * .95) + .05;
  }

  vec3 ambient_color =
    ambient_currentlight * illumination.y;
  vec3 candle_color =
    candle_baselight * illumination.x * illumination.x * illumination.x;

  // Se ajusta luz ambiental en tormenta
  ambient_color = ambient_color * (1.0 - (rainStrength * .4));

  vec3 real_light =
    mix(ambient_color + candle_color, vec3(1.0), nightVision * .125);

  // Toma el color puro del bloque
  vec4 block_color = texture2D(texture, texcoord.xy);

  // Se agrega mapa de color y sombreado nativo
  block_color *= (tint_color * vec4(real_light, 1.0));

  // Posproceso de la niebla
  if (isEyeInWater == 1.0) {
  block_color.rgb =
      mix(
        block_color.rgb,
        waterfog_baselight * real_light,
        1.0 - clamp(exp(-gl_Fog.density * gl_FogFragCoord), 0.0, 1.0)
      );
  } else if (isEyeInWater == 2.0) {
    block_color.rgb =
      mix(
        block_color.rgb,
        gl_Fog.color.rgb * real_light,
        1.0 - clamp(exp(-gl_Fog.density * gl_FogFragCoord), 0.0, 1.0)
      );
  } else {
    // Fog intensity calculation
    float fog_intensity_coeff = mix(
      fog_density[int(floor(current_hour))],
      fog_density[int(ceil(current_hour))],
      fract(current_hour)
      );
    fog_intensity_coeff = max(fog_intensity_coeff, wetness);
    float new_frog = (((gl_FogFragCoord / far) * (2.0 - fog_intensity_coeff)) - (1.0 - fog_intensity_coeff)) * far;
    float frog_adjust = new_frog / far;

    // Fog color calculation
    float fog_mix_level = mix(
      fog_color_mix[int(floor(current_hour))],
      fog_color_mix[int(ceil(current_hour))],
      fract(current_hour)
      );
    vec3 current_fog_color = mix(skyColor, gl_Fog.color.rgb, fog_mix_level);

    block_color.rgb =
      mix(
        block_color.rgb,
        current_fog_color,
        pow(clamp(frog_adjust, 0.0, 1.0), 2)
      );
  }

  gl_FragData[0] = block_color;
  gl_FragData[1] = vec4(0.0);  // Not needed. Performance trick
  gl_FragData[5] = block_color;
}
