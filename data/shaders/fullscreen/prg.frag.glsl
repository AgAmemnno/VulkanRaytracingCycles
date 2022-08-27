#version 450
layout (location = 0) in vec2 inUV;


layout (std140, push_constant) uniform PushConsts
{
	mat4   model;
	vec4   color;
    uvec4  dim;

};




layout (location = 0) out vec4 outFragColor;


void main()
{


    outFragColor   = vec4(inUV,0.,1.);

}


