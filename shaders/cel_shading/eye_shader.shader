shader_type spatial;



uniform vec4 albedo : hint_color = vec4(1.0);
uniform sampler2D texturemap : hint_albedo;
uniform sampler2D light_ramp : hint_black;

uniform vec3 eye_light_default = vec3(0.2);

void fragment() {
	ALBEDO = texture(texturemap, UV).rgb;
}


void light() {
	float NdotL = dot(NORMAL, LIGHT);
	
	NdotL = (NdotL + 1.0) / 2.0; //squeeze value of NdotL between 0 and 1
	
	float light_factor = (length(ATTENUATION) + NdotL) / 2.0; //combine NdotL and length of attenuation, then squeeze between 0 and 1
	
	float light_value = texture(light_ramp, vec2(light_factor, 0)).r; //use NdotL as U value to get light value from light ramp
	
	
	vec3 light_color = eye_light_default + (((vec3(1.0) - eye_light_default) * LIGHT_COLOR) * light_factor);
	
	
	
	vec3 lit_color = ALBEDO * light_color * light_value;
	vec3 shadowed_color = ALBEDO * eye_light_default;
	
	//Determine shade color
	vec3 out_color = max(lit_color, shadowed_color);
	
	//Only overwrite with out_color if greater than DIFFUSE_LIGHT
	if (length(DIFFUSE_LIGHT / ALBEDO) < length(out_color / ALBEDO))
		DIFFUSE_LIGHT = out_color;
	else
		DIFFUSE_LIGHT = DIFFUSE_LIGHT;
}










