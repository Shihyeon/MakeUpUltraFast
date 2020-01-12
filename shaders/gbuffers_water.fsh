#version 120
/* MakeUp Ultra Fast - gbuffers_water.fsh
Render: Water and translucent blocks

Javier Garduño - GNU Lesser General Public License v3.0
*/

#include "/lib/globals.glsl"

#define NICE_WATER 1 // [0 1] Turn on for reflection and refraction capabilities.
#define TINTED_WATER 1 // [0 1] Use the resource pack color for water.
#define REFLECTION 1 // [0 1] Activate reflectons
#define REFRACTION 1 // [0 1] Activate refractions
#define SSR_METHOD 0 // [0 1] Select reflection method

const int noiseTextureResolution  = 128;

// Varyings (per thread shared variables)
varying vec4 texcoord;
varying vec4 lmcoord;
varying vec4 tint_color;
varying vec3 my_normal;
varying vec4 normal;
varying vec3 sun_vec;
varying vec3 moon_vec;
varying float iswater;
varying float istranslucent;
varying vec4 position2;
varying vec4 worldposition;
varying vec3 tangent;
varying vec3 binormal;

// 'Global' constants from system
uniform int worldTime;
uniform sampler2D texture;
uniform sampler2D lightmap;
uniform int isEyeInWater;
uniform int entityId;
uniform float nightVision;
uniform float rainStrength;
uniform float wetness;
uniform float near;
uniform float far;
uniform vec3 skyColor;
uniform float frameTimeCounter;
uniform sampler2D noisetex;
uniform float sunAngle;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferProjection;
uniform float viewWidth;
uniform float viewHeight;
uniform sampler2D gcolor;
uniform sampler2D gdepth;
uniform sampler2D gnormal;
uniform sampler2D composite;
uniform sampler2D gaux2;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform vec3 sunPosition;

#include "/lib/color_utils.glsl"
#include "/lib/water.glsl"

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

  illumination.y = pow(illumination.y, 3);  // Non-linear decay
  illumination.y = (illumination.y * .99) + .01;  // Avoid absolute dark

  // Ajuste de intensidad luminosa bajo el agua
  if (isEyeInWater == 1.0) {
    illumination.y = (illumination.y * .95) + .05;
  }

  vec3 ambient_color =
    ambient_currentlight * illumination.y;
  vec3 candle_color =
    candle_baselight * pow(illumination.x, 4);  // Non-linear decay

  // Se ajusta luz ambiental en tormenta
  ambient_color = ambient_color * (1.0 - (rainStrength * .4));

  vec3 real_light =
    mix(ambient_color + candle_color, vec3(1.0), nightVision * .125);

  // Indica cuanta iluminación basada en dirección de fuente de luz se usará
  float direct_light_coefficient = clamp(lmcoord.y * 2.0 - 1.0, 0.0, 1.0);
  float direct_light_strenght = 1.0;

   // Si no estamos ocultos al cielo calculamos iluminación de dirección
  if (direct_light_coefficient > 0.0) {
    if ((worldTime >= 0 && worldTime <= 12700) || worldTime > 23000) {  // Día
      direct_light_strenght = dot(my_normal, sun_vec);
    //
    } else if (worldTime > 12700 && worldTime <= 13400 ) { // Anochece
      float sun_light_strenght = dot(my_normal, sun_vec);
      float moon_light_strenght = dot(my_normal, moon_vec);
      float light_mix = (worldTime - 12700) / 700.0;
      // Calculamos la cantidad de mezcla de luz de sol y luna
      direct_light_strenght =
        mix(sun_light_strenght, moon_light_strenght, light_mix);

    } else if (worldTime > 13400 && worldTime <= 22300) {  // Noche
      direct_light_strenght = dot(my_normal, moon_vec);

    } else if (worldTime > 22300) {  // Amanece
      float sun_light_strenght = dot(my_normal, sun_vec);
      float moon_light_strenght = dot(my_normal, moon_vec);
      float light_mix = (worldTime - 22300) / 700.0;
      // Calculamos la cantiidad de mezcla de luz de sol y luna
      direct_light_strenght =
        mix(moon_light_strenght, sun_light_strenght, light_mix);
    }

    // Escalamos para evitar negros en zonas oscuras
    direct_light_strenght = direct_light_strenght * .4 + .6;
    direct_light_strenght =
      mix(1.0, direct_light_strenght, direct_light_coefficient);
  }

  // Prepare Sky/Fog color calculation
  float fog_mix_level = mix(
    fog_color_mix[int(floor(current_hour))],
    fog_color_mix[int(ceil(current_hour))],
    fract(current_hour)
    );
    // Fog color calculation
  vec3 current_fog_color = mix(skyColor, gl_Fog.color.rgb, fog_mix_level);

  // Begin water code ---------------

  vec4 block_color;

  if (iswater > .5) {

    #if NICE_WATER == 1

      #if TINTED_WATER == 1
        block_color.rgb = tint_color.rgb * direct_light_strenght;
      #else
        block_color.rgb = vec3(1.0);
      #endif

      vec3 water_normal_base = waterwavesToNormal(worldposition.xyz);

      vec3 fragposition0 = toNDC(vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z));

      block_color = vec4(
  			refraction(
  				fragposition0,
  				block_color.rgb,
  				water_normal_base
  			),
  			1.0
  		);

      block_color.rgb = waterShader(
        fragposition0.xyz,
        getNormals(water_normal_base),
        block_color.rgb,
        lmcoord.y > 0.9? 1.0 : 0.0,
        current_fog_color
      );

    #else
      // Toma el color puro del bloque
      block_color = texture2D(texture, texcoord.xy);
      // Se agrega mapa de color y sombreado nativo
      block_color *= (tint_color * vec4(real_light, 1.0));
      // Iluminación propia
      block_color.rgb *= direct_light_strenght;
      block_color.a = .66;
    #endif

  } else {  // End water shader code ------------------------
    // Toma el color puro del bloque
    block_color = texture2D(texture, texcoord.xy);
    // Se agrega mapa de color y sombreado nativo
    block_color *= (tint_color * vec4(real_light, 1.0));
    // Iluminación propia
    block_color.rgb *= direct_light_strenght;
  }

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

    block_color.rgb =
      mix(
        block_color.rgb,
        current_fog_color,
        pow(clamp(frog_adjust, 0.0, 1.0), 2)
      );
  }

  gl_FragData[0] = block_color;
  gl_FragData[1] = vec4(0.0);  // Not needed. Performance trick
  gl_FragData[4] = vec4(0.0);
}
