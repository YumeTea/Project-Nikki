shader_type spatial;
render_mode cull_disabled;

//Color Variables
uniform sampler2D texturemap : hint_albedo;
uniform vec4 albedo : hint_color;
uniform sampler2D viewport_texture : hint_albedo;

//Texture Variables
uniform vec2 tile_factor = vec2(1.0, 1.0);
uniform vec2 aspect_ratio = vec2(1.0, 1.0);
uniform bool transparent = true;

//Edge Variables
uniform vec4 water_color : hint_color;
uniform float fresnel_power : hint_range(0, 2) = 1;
uniform float edge_intensity : hint_range(0, 2) = 1;

//Wave Variables
uniform vec2 wave_amount = vec2(5.0, 5.0);
uniform vec2 offset_scale = vec2(0.1, 0.1);
uniform vec2 time_scale = vec2(0.6, 0.9);
uniform vec2 amplitude = vec2(0.4, 0.4);

//Refraction Variables
uniform float refraction = 0.08;


void fragment() {
	//Tiling of UVs
	vec2 tiled_uvs = UV * tile_factor;
	tiled_uvs *= (aspect_ratio.x / aspect_ratio.y);

	//Waves
	vec2 wave_offset;
	//X Wave Offset
	wave_offset.x = (sin(TIME * time_scale.x + (tiled_uvs.y * wave_amount.y)) * offset_scale.x) * amplitude.x;
	wave_offset.x *= tiled_uvs.y - 0.5; //subtract 0.5 to offset from center instead of corner
	
	//Y Wave Offset
	wave_offset.y = (cos(TIME * time_scale.y + (tiled_uvs.y * wave_amount.y)) * offset_scale.y) * amplitude.y;
	wave_offset.y *= tiled_uvs.x - 0.5; //subtract 0.5 to offset from center instead of corner
	
	tiled_uvs += wave_offset;
	
	//Texture
	ALBEDO = texture(texturemap, tiled_uvs).rgb;
	
	//DEPTH DARKENING
	float depth = texture(DEPTH_TEXTURE, SCREEN_UV).r * 2.0 - 1.0; // convert depth buffer to -1 to 1 range
	
	//Transforms depth into an intersection
	//intersection is 0 at intersection point
	depth = PROJECTION_MATRIX[3][2] / (depth + PROJECTION_MATRIX[2][2]);
	depth += VERTEX.z;
	
	depth = pow(clamp(depth, 0, 1), fresnel_power) * edge_intensity;
	
	ALBEDO = mix(ALBEDO, water_color.rgb, depth);
	
	//Transparency
	ALPHA = albedo.a;
	
//	METALLIC = 0.0;
//	ROUGHNESS = 0.0;
	
	//Refraction
//	vec3 ref_normal = normalize(mix(NORMAL, TANGENT * NORMALMAP.x + BINORMAL * NORMALMAP.y + NORMAL * NORMALMAP.z, NORMALMAP_DEPTH));
//	vec2 ref_ofs = SCREEN_UV - ref_normal.xy * refraction;
//	EMISSION += textureLod(viewport_texture, SCREEN_UV, ROUGHNESS * 8.0).rgb * (1.0 - ALPHA);
//	ALBEDO *= ALPHA;
//	ALPHA = 1.0;
}














