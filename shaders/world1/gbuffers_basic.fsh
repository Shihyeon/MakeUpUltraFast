#version 120
#extension GL_EXT_gpu_shader4 : enable
/* MakeUp - gbuffers_basic.fsh
Render: Basic elements - lines

Javier Garduño - GNU Lesser General Public License v3.0
*/

#define THE_END
#define GBUFFER_BASIC
#define NO_SHADOWS

#include "/common/basic_blocks_fragment.glsl"
