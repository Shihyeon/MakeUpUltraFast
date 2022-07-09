/* MakeUp - fast_taa.glsl
Temporal antialiasing functions.

Javier Garduño - GNU Lesser General Public License v3.0
*/

vec3 fast_taa(vec3 current_color, vec2 texcoord_past, vec2 velocity, float pixel_size_x, float pixel_size_y) {
  // Verificamos si proyección queda fuera de la pantalla actual
  if (clamp(texcoord_past, 0.0, 1.0) != texcoord_past) {
    return current_color;
  } else {
    vec3 neighbourhood[5];

    // neighbourhood[0] = texture2D(colortex1, texcoord + vec2(-pixel_size_x, -pixel_size_y)).rgb;
    // neighbourhood[1] = texture2D(colortex1, texcoord + vec2(pixel_size_x, -pixel_size_y)).rgb;
    // neighbourhood[2] = current_color;
    // neighbourhood[3] = texture2D(colortex1, texcoord + vec2(-pixel_size_x, pixel_size_y)).rgb;
    // neighbourhood[4] = texture2D(colortex1, texcoord + vec2(pixel_size_x, pixel_size_y)).rgb;

    neighbourhood[0] = texture2D(colortex1, texcoord + vec2(-pixel_size_x, 0.0)).rgb;
    neighbourhood[1] = texture2D(colortex1, texcoord + vec2(pixel_size_x, 0.0)).rgb;
    neighbourhood[2] = current_color;
    neighbourhood[3] = texture2D(colortex1, texcoord + vec2(0.0, -pixel_size_y)).rgb;
    neighbourhood[4] = texture2D(colortex1, texcoord + vec2(0.0, pixel_size_y)).rgb;

    vec3 nmin = neighbourhood[0];
    vec3 nmax = nmin;
    for(int i = 1; i < 5; ++i) {
      nmin = min(nmin, neighbourhood[i]);
      nmax = max(nmax, neighbourhood[i]);
    }

    // Muestra del pasado
    vec3 previous = texture2D(colortex3, texcoord_past).rgb;
    vec3 past_sample = clamp(previous, nmin, nmax);

    // Edge detection
    vec3 edge_color = -neighbourhood[0];
    edge_color -= neighbourhood[1];
    edge_color += neighbourhood[2] * 4.0;
    edge_color -= neighbourhood[3];
    edge_color -= neighbourhood[4];

    // float edge = (length(edge_color) * 0.5773502691896258) * 0.14;  // 1/sqrt(3) * 0.14
    float edge = length(edge_color) * 0.08082903768654763;  // 1/sqrt(3) * 0.14

    return mix(current_color, past_sample, clamp(0.8 + edge, 0.0, 1.0));
  }
}

// vec3 fast_taa(vec3 current_color, vec2 texcoord_past, vec2 velocity, float pixel_size_x, float pixel_size_y) {
//   // Verificamos si proyección queda fuera de la pantalla actual
//   if (clamp(texcoord_past, 0.0, 1.0) != texcoord_past) {
//     return current_color;
//   } else {
//     vec3 neighbourhood[5];

//     neighbourhood[0] = texture2D(colortex1, texcoord + vec2(-pixel_size_x, -pixel_size_y)).rgb;
//     neighbourhood[1] = texture2D(colortex1, texcoord + vec2(pixel_size_x, -pixel_size_y)).rgb;
//     neighbourhood[2] = current_color;
//     neighbourhood[3] = texture2D(colortex1, texcoord + vec2(-pixel_size_x, pixel_size_y)).rgb;
//     neighbourhood[4] = texture2D(colortex1, texcoord + vec2(pixel_size_x, pixel_size_y)).rgb;

//     vec3 nmin = neighbourhood[0];
//     vec3 nmax = nmin;
//     for(int i = 1; i < 5; ++i) {
//       nmin = min(nmin, neighbourhood[i]);
//       nmax = max(nmax, neighbourhood[i]);
//     }

//     // Muestra del pasado
//     vec3 previous = texture2D(colortex3, texcoord_past).rgb;
//     vec3 past_sample = clamp(previous, nmin, nmax);

//     // Reducción de ghosting por velocidad
//     float blend = exp(-length(velocity * vec2(viewWidth, viewHeight))) * 0.175 + 0.7;

//     return mix(current_color, past_sample, clamp(blend, 0.0, 1.0));
//   }
// }

vec4 fast_taa_depth(vec4 current_color, vec2 texcoord_past, vec2 velocity, float pixel_size_x, float pixel_size_y) {
  // Verificamos si proyección queda fuera de la pantalla actual
  if (clamp(texcoord_past, 0.0, 1.0) != texcoord_past) {
    return current_color;
  } else {
    vec4 neighbourhood[5];

    // neighbourhood[0] = texture2D(colortex1, texcoord + vec2(-pixel_size_x, -pixel_size_y));
    // neighbourhood[1] = texture2D(colortex1, texcoord + vec2(pixel_size_x, -pixel_size_y));
    // neighbourhood[2] = current_color;
    // neighbourhood[3] = texture2D(colortex1, texcoord + vec2(-pixel_size_x, pixel_size_y));
    // neighbourhood[4] = texture2D(colortex1, texcoord + vec2(pixel_size_x, pixel_size_y));

    neighbourhood[0] = texture2D(colortex1, texcoord + vec2(-pixel_size_x, 0.0));
    neighbourhood[1] = texture2D(colortex1, texcoord + vec2(pixel_size_x, 0.0));
    neighbourhood[2] = current_color;
    neighbourhood[3] = texture2D(colortex1, texcoord + vec2(0.0, -pixel_size_y));
    neighbourhood[4] = texture2D(colortex1, texcoord + vec2(0.0, pixel_size_y));

    vec4 nmin = neighbourhood[0];
    vec4 nmax = nmin;
    for(int i = 1; i < 5; ++i) {
      nmin = min(nmin, neighbourhood[i]);
      nmax = max(nmax, neighbourhood[i]);
    }

    // Muestra del pasado
    vec4 previous = texture2D(colortex3, texcoord_past);
    vec4 past_sample = clamp(previous, nmin, nmax);

    // Edge detection
    vec3 edge_color = -neighbourhood[0].rgb;
    edge_color -= neighbourhood[1].rgb;
    edge_color += neighbourhood[2].rgb * 4.0;
    edge_color -= neighbourhood[3].rgb;
    edge_color -= neighbourhood[4].rgb;

    // float edge = (length(edge_color) * 0.5773502691896258) * 0.14;  // 1/sqrt(3) * 0.14
    float edge = length(edge_color) * 0.08082903768654763;  // 1/sqrt(3) * 0.14

    return mix(current_color, past_sample, clamp(0.8 + edge, 0.0, 1.0));
  }
}
