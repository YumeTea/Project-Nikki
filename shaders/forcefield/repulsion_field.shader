shader_type spatial;

render_mode depth_draw_opaque, cull_disabled, ambient_light_disabled, shadows_disabled, blend_add;

uniform vec4 color : hint_color;
uniform float fresnel_power = 1.0; //controls fresnel thickness
uniform float edge_intensity = 2.0; //controls fresnel thickness
uniform float fill_amount : hint_range(0, 1) = 0.1; 

uniform float pulsing_strength : hint_range(0, 10) = 0.1;
uniform float pulsing_speed : hint_range(0, 10) = 0.1;

uniform vec2 pattern_uv_offset = vec2(6.0, 3.0);

uniform sampler2D pattern_texture : hint_albedo;


void vertex() {
	float pulse_distance = ((sin(TIME * pulsing_speed) * 0.1)) * pulsing_strength;
	VERTEX += NORMAL * pulse_distance;
}


void fragment() {
	//FRESNEL
	//1 - dot(NORMAL, VIEW) reverses dot product and makes edges 1 and center 0
	float fresnel = pow(1.0 - dot(NORMAL, VIEW), fresnel_power) * edge_intensity;
	fresnel = fresnel + fill_amount; //add back in to transparent areas
	
	//DEPTH
	float depth = texture(DEPTH_TEXTURE, SCREEN_UV).r * 2.0 - 1.0; // convert depth buffer to -1 to 1 range
	
	//Transforms depth into an intersection (distance from surface to geometry behind it)
	depth = PROJECTION_MATRIX[3][2] / (depth + PROJECTION_MATRIX[2][2]);
	depth += VERTEX.z;
	
	depth = pow(1.0 - clamp(depth, 0, 1), fresnel_power) * edge_intensity;
	
	fresnel = fresnel + depth;
	
	//PATTERN
	//Multiply in the pattern_texture if there is one
	vec4 pattern = texture(pattern_texture, (UV * pattern_uv_offset));
	fresnel *= pattern.r;
	
	//FINAL RESULT
	ALBEDO = vec3(0.0); //ALBEDO is black so light information does not interfere
	EMISSION = color.rgb;
	ALPHA = smoothstep(0.0, 1.0, fresnel);
}








