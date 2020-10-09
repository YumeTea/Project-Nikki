shader_type spatial;
render_mode depth_test_disable, shadows_disabled, ambient_light_disabled;

uniform vec4 albedo : hint_color;

//Water Overlay Variables
uniform bool underwater;
uniform vec2 amplitude = vec2(0.02, 0.02);
uniform vec2 frequency = vec2(2.0, 3.0);
uniform vec2 time_factor = vec2(0.8, 1.2);
uniform float refraction = 0.01;


float height(vec2 pos, float time) {
	return (amplitude.x * sin(pos.x * frequency.x * time * time_factor.x) + (amplitude.y * sin(pos.y * frequency.y * time * time_factor.y)));
}


void vertex() {
	if (underwater) {
		VERTEX.y -= height(VERTEX.xz, TIME);
		
		TANGENT = normalize(vec3(0.0, height(VERTEX.xz + vec2(0.0, 0.2), TIME) - height(VERTEX.xz + vec2(0.0, -0.2), TIME), 0.4));
		
		BINORMAL = normalize(vec3(0.4, height(VERTEX.xz + vec2(0.2, 0.0), TIME) - height(VERTEX.xz + vec2(-0.2, 0.0), TIME), 0.0));
		
		NORMAL = cross(TANGENT, BINORMAL);
	}
}


void fragment() {
	NORMALMAP = NORMAL;
	
	ALBEDO = albedo.xyz;
	ALPHA = albedo.a;
	
	METALLIC = 0.0;
	ROUGHNESS = 0.0;
	
	//Refraction
	vec3 ref_normal = normalize(mix(NORMAL, TANGENT * NORMALMAP.x + BINORMAL * NORMALMAP.y + NORMAL * NORMALMAP.z, NORMALMAP_DEPTH));
	vec2 ref_ofs = SCREEN_UV - ref_normal.xy * refraction;
	EMISSION += textureLod(SCREEN_TEXTURE, ref_ofs, ROUGHNESS * 8.0).rgb * (1.0 - ALPHA);
	ALBEDO *= ALPHA;
	ALPHA = 1.0;
}



