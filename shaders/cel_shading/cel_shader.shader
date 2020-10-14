shader_type spatial;
render_mode depth_draw_opaque;

//Currently, shader sets diffuse value to brightest light hitting pixel

uniform vec4 albedo : hint_color = vec4(1.0);
uniform sampler2D texturemap : hint_albedo;
uniform sampler2D light_ramp : hint_black;

uniform vec4 emission : hint_color;
uniform float emission_energy : hint_range(0.0, 16.0);

uniform vec4 highlight_color : hint_color = vec4(0.0, 0.57, 0.67, 1.0);
uniform float highlight_strength : hint_range(0.0, 1.0) = 0.8;

uniform bool highlighted = false;
uniform bool transparent = false;
uniform bool shaded = true;


//uniform vec4 shadow_color : hint_color = vec4(0.36, 0.36, 0.36, 1.0);


void vertex() {
	COLOR.a = albedo.a;
}

void fragment() {
	//ALBEDO
	ALBEDO = texture(texturemap, UV).rgb * albedo.rgb;
	
	//EMISSION
	if (highlighted == true) {
		vec3 highlight = mix(ALBEDO, highlight_color.rgb, highlight_strength);
		EMISSION = highlight;
	}
	else {
		if (emission.rgb != vec3(0.0)){
			EMISSION = emission.rgb;
		}
	}
	
//	//TRANSPARENCY
//	if (transparent == true) {
//		ALPHA = albedo.a;
//	}
}


void light() {
	float NdotL = dot(NORMAL, LIGHT);

	NdotL = (NdotL + 1.0) / 2.0; //squeeze value of NdotL between 0 and 1

	float light_factor = (length(ATTENUATION) + NdotL) / 2.0; //combine NdotL and length of attenuation, then squeeze between 0 and 1

	float light_value = texture(light_ramp, vec2(light_factor, 0.0)).r; //use NdotL as U value to get light value from light ramp

	//If unshaded, light value is treated as pure black (only ambient light affects pixel)
	if (shaded == false)
		light_value = 0.0;

	vec3 lit_color = ALBEDO * LIGHT_COLOR * light_value;
	vec3 shadowed_color = vec3(0.0);

	//Determine shade color
	vec3 out_color = max(lit_color, shadowed_color);

	//Only overwrite with out_color if brighter than DIFFUSE_LIGHT
	if (length(DIFFUSE_LIGHT / ALBEDO) < length(out_color / ALBEDO))
		DIFFUSE_LIGHT = out_color;
	else
		DIFFUSE_LIGHT = DIFFUSE_LIGHT;
}










