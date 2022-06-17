#version 120
#extension GL_EXT_gpu_shader4 : enable
/* MakeUp - gbuffers_armor_glint.vsh
Render: Glow objects

Javier Garduño - GNU Lesser General Public License v3.0
*/

#define GBUFFER_ARMOR_GLINT
#define ENTITY_GLINT
#define SHADER_BASIC

#include "/common/glint_blocks_vertex.glsl"