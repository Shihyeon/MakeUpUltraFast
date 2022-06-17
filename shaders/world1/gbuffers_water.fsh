#version 120
#extension GL_EXT_gpu_shader4 : enable
/* MakeUp - gbuffers_water.fsh
Render: Water and translucent blocks

Javier Garduño - GNU Lesser General Public License v3.0
*/

#define THE_END
#define GBUFFER_WATER
#define WATER_F

#include "/common/water_blocks_fragment.glsl"
