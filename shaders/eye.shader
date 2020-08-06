shader_type spatial;
render_mode diffuse_toon, specular_toon, ambient_light_disabled;

uniform sampler2D texturemap : hint_albedo;


void vertex() {
}

void fragment() {
	ALBEDO = texture(texturemap, UV).rgb;
}

void light() {
	DIFFUSE_LIGHT += LIGHT_COLOR * ALBEDO/5.0;
}

