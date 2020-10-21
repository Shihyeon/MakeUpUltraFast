#ifdef NETHER
  tint_color = gl_Color;
  vec3 normal = normalize(gl_NormalMatrix * gl_Normal);

  // Luz nativa (lmcoord.x: candela, lmcoord.y: cielo) ----
  vec2 illumination = lmcoord;

  vec3 direct_light_color =
    mix(
      ambient_baselight[current_hour_floor],
      ambient_baselight[current_hour_ceil],
      current_hour_fract
    );
  vec3 candle_color = candle_baselight * cube_pow(illumination.x);

  real_light = direct_light_color + candle_color;
#else

  tint_color = gl_Color;

  #ifdef EMMISIVE_V
  if (emissive > 0.5 || magma > 0.5) {  // Es bloque es emisivo
    tint_color.rgb *= 1.5;
  }
  #endif

  // Luz nativa (lmcoord.x: candela, lmcoord.y: cielo) ----
  vec2 illumination = lmcoord;

  // Intensidad según mirada al cielo ==========================================
  illumination.y = max(illumination.y, 0.095);  // Remueve artefacto

  // Visibilidad del cielo
  float visible_sky = illumination.y * 1.105 - .10495;

  // Ajuste de intensidad luminosa bajo el agua
  if (isEyeInWater == 1) {
    illumination.y = (illumination.y * .95) + .05;
  }

  // Intensidad y color de luz de candelas
  candle_color = candle_baselight * cube_pow(illumination.x);

  // Atenuación por dirección de luz directa =================================
  #ifdef THE_END
    vec3 sun_vec = normalize(gbufferModelView[1].xyz);
  #else
    vec3 sun_vec = normalize(sunPosition);
  #endif

  vec3 normal = normalize(gl_NormalMatrix * gl_Normal);
  float sun_light_strenght = dot(normal, sun_vec);

  #ifdef THE_END
    direct_light_strenght = sun_light_strenght;
  #else
    direct_light_strenght =
      mix(-sun_light_strenght, sun_light_strenght, light_mix);
  #endif

  shadow_mask = direct_light_strenght;

  // Intensidad por dirección
  direct_light_strenght = clamp(direct_light_strenght, 0.0, 1.0);

  // Calculamos color de luz directa
  #ifdef THE_END
    direct_light_color =
      mix(
        ambient_baselight[current_hour_floor],
        ambient_baselight[current_hour_ceil],
        current_hour_fract
      );
  #else
    direct_light_color =
      mix(
        ambient_baselight[current_hour_floor],
        ambient_baselight[current_hour_ceil],
        current_hour_fract
      );
  #endif

  // Calculamos color de luz ambiental
  omni_light = mix(skyColor, direct_light_color, 0.35) * mix(
    omni_force[current_hour_floor],
    omni_force[current_hour_ceil],
    current_hour_fract
  ) * visible_sky * 4.0;

  #ifdef CAVEENTITY_V
    // Para evitar iluminación plana en cuevas
    float candle_cave_strenght = (direct_light_strenght * .5) + .5;
    candle_cave_strenght =
      mix(candle_cave_strenght, 1.0, visible_sky);
    candle_color *= candle_cave_strenght;
  #endif

  #ifdef FOLIAGE_V  // Puede haber plantas en este shader
    if (
      mc_Entity.x == ENTITY_SMALLGRASS ||
      mc_Entity.x == ENTITY_LOWERGRASS ||
      mc_Entity.x == ENTITY_VINES ||
      mc_Entity.x == ENTITY_UPPERGRASS ||
      mc_Entity.x == ENTITY_SMALLENTS ||
      mc_Entity.x == ENTITY_LEAVES
    ) {  // Es "planta" y se atenúa el impacto de la atenuación por dirección
      direct_light_strenght = mix(direct_light_strenght, 1.0, .75);
    }
  #endif

  #ifndef THE_END
    direct_light_strenght = mix(0.0, direct_light_strenght, visible_sky);
  #endif

#endif
