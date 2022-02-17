#ifdef FOLIAGE_V
  float NdotL;
  if (is_foliage > .2) {
    #ifdef THE_END
      vec3 custom_light_pos = normalize(gbufferModelView * vec4(0.0, 0.89442719, 0.4472136, 0.0)).xyz;
      NdotL = clamp(
        max(
          dot(normal, custom_light_pos),
          dot(-normal, custom_light_pos)
        ),
        0.0,
        1.0
        );
    #else
      vec3 normal_light_pos = normalize(shadowLightPosition);
      NdotL = clamp(
        max(
          dot(normal, normal_light_pos),
          dot(-normal, normal_light_pos)
        ),
        0.0,
        1.0
        );
    #endif
  } else {
    #ifdef THE_END
      NdotL = clamp(
        dot(
          normal,
          normalize(gbufferModelView * vec4(0.0, 0.89442719, 0.4472136, 0.0)).xyz
          ),
        0.0,
        1.0
        );
    #else
      NdotL = clamp(
        dot(
          normal,
          normalize(shadowLightPosition)
          ),
        0.0,
        1.0
        );
    #endif
  }
#else
  #ifdef THE_END
    float NdotL = clamp(
      dot(
        normal,
        normalize(gbufferModelView * vec4(0.0, 0.89442719, 0.4472136, 0.0)).xyz
        ),
      0.0,
      1.0
      );
  #else
    float NdotL = clamp(
      dot(
        normal,
        normalize(shadowLightPosition)
        ),
      0.0,
      1.0
      );
  #endif
#endif

shadow_pos = get_shadow_pos(position.xyz, NdotL);

vec2 shadow_diffuse_aux = pow((shadow_pos.xy - 0.5) * 2.05, vec2(2.0));
shadow_diffuse = sqrt(shadow_diffuse_aux.x + shadow_diffuse_aux.y);
shadow_diffuse = clamp(pow(shadow_diffuse, 12.0), 0.0, 1.0);
