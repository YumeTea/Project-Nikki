shader_type spatial;
render_mode cull_disabled, diffuse_toon, specular_toon;

uniform sampler2D texturemap : hint_albedo;
uniform sampler2D normalmap : hint_normal;
uniform vec4 shadow_color : hint_color = vec4(0.9, 0.9, 0.9, 1.0);


void vertex() {
}


void fragment() {
	ALBEDO = texture(texturemap, UV).rgb;
}


void light() {
	float attenuation = round((length(ATTENUATION) * 2.0)) / 2.8;
	vec3 Attenuation = vec3(attenuation, attenuation, attenuation);

	//converts Albedo to vec4
	vec3 color = vec3(ALBEDO.r, ALBEDO.g, ALBEDO.b);
	vec3 shadow = (color * shadow_color.rgb);

	if (attenuation > 0.0) {
		DIFFUSE_LIGHT += LIGHT_COLOR * ALBEDO/3.5;
	}
	else {
		DIFFUSE_LIGHT += LIGHT_COLOR * ALBEDO/12.9;
	}
}

