shader_type spatial;
render_mode specular_toon;

void fragment() {
	RIM = 0.0;
	METALLIC = 0.0;
	ROUGHNESS = 1.0;
	ALBEDO = vec3(0.06, 0.01, 0.01);
}