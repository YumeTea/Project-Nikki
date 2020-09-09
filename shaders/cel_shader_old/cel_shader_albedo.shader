shader_type spatial;
render_mode diffuse_toon, specular_toon, ambient_light_disabled;

uniform sampler2D texturemap : hint_albedo;
//uniform float cut_point : hint_range(0.0, 1.0);
//uniform float light_intensity = 0.06;
uniform vec4 albedo : hint_color = vec4(0.0,0.0,0.0,1.0);
uniform vec4 shadow_color : hint_color = vec4(0.9, 0.9, 0.9, 1.0);


void vertex() {
}

void fragment() {
	ALBEDO = albedo.rgb;
}

void light() {
	//dot product of Light vector and Normal vector of surface. Ceil so 1 is lit and 0,-1 is shadow
//	float NdotL = dot(NORMAL, LIGHT) * 3.0;
//	if (NdotL < 0.0) {
//		NdotL = 0.0
//	}
//	NdotL = ceil(NdotL);
	
	//convert Attenuation vector to magnitude of light. Round so 1 is lit and 0 is shadow
//	float attenuation = round((length(ATTENUATION) * 0.6));
//	float attenuation = round((length(ATTENUATION) * 3.6)) / 4.0;
	float attenuation = round((length(ATTENUATION) * 2.0)) / 2.8;
	vec3 Attenuation = vec3(attenuation, attenuation, attenuation);

	//converts Albedo to vec4
	vec3 color = vec3(ALBEDO.r, ALBEDO.g, ALBEDO.b);
	vec3 shadow = (color * shadow_color.rgb);

	if (attenuation > 0.0) {
		DIFFUSE_LIGHT += Attenuation * LIGHT_COLOR * ALBEDO/4.0;
	}
	else {
		DIFFUSE_LIGHT += LIGHT_COLOR * ALBEDO/9.0;
	}
	
	
	//DEBUG
//	DIFFUSE_LIGHT = vec3(NdotL, NdotL, NdotL);
//	DIFFUSE_LIGHT = mix(ALBEDO/2.0, LIGHT_COLOR, light_intensity);
//	DIFFUSE_LIGHT += vec3(attenuation, attenuation, attenuation);
//	SPECULAR_LIGHT += vec3(attenuation, attenuation, attenuation) * ALBEDO / 3.0;
//	DIFFUSE_LIGHT += Attenuation;
}

