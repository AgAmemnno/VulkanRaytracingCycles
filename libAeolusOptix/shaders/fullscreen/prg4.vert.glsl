#version 450

out layout(location = 0) vec2 oUV;



out gl_PerVertex
{
	vec4 gl_Position;
};

vec3 pos[4] = vec3[4](
    vec3(-1,-1,0),
    vec3(1,-1,0),
    vec3(-1,1,0),
    vec3(1,1,0)
);

void main(void)
{

	gl_Position   =  vec4(pos[gl_VertexIndex], 1.0);
    gl_Position.y   *= -1;
	oUV    = gl_Position.xy*0.5 + 0.5;
}
