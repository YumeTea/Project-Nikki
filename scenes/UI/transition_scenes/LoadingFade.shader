shader_type canvas_item;
render_mode unshaded;

uniform float cutoff : hint_range(0.0, 1.0);
uniform sampler2D mask : hint_albedo;

//Fragment Shader
void fragment()
{
	COLOR.r = 0.0;
	COLOR.g = 0.0;
	COLOR.b = 0.0;
	COLOR.a = cutoff;
}