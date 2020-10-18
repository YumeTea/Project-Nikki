shader_type canvas_item;

uniform float light_level;
uniform vec4 color_dark : hint_color = vec4(0.04, 0.01, 0.18, 1.0);
uniform vec4 color_bright : hint_color = vec4(0.96, 0.98, 0.5, 1.0);



void fragment() {
	float illumination = light_level / 100.0;
	
	vec4 color = mix(color_dark, color_bright, illumination);
	color.a += illumination;
	
	COLOR = texture(TEXTURE, UV) * color;
}




