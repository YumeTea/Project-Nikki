shader_type spatial;
render_mode depth_test_disable, diffuse_toon;

uniform vec4 albedo : hint_color;


void fragment() {
	ALBEDO = albedo.xyz;
	ALPHA = albedo.a;
}



