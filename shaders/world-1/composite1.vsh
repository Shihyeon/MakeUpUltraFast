#version 120
#extension GL_EXT_gpu_shader4 : enable
/* MakeUp - composite1.fsh
Render: Bloom and DoF

Javier Garduño - GNU Lesser General Public License v3.0
*/

#define NETHER
#define COMPOSITE1_SHADER
#define NO_SHADOWS

#include "/common/composite1_vertex.glsl"
