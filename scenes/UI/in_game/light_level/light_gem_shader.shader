shader_type canvas_item;

uniform float light_level;
uniform vec4 color_dark : hint_color = vec4(0.04, 0.01, 0.17, 0.88);
uniform vec4 color_bright : hint_color = vec4(0.96, 0.98, 0.5, 0.88);



void fragment() {
	float illumination = light_level / 100.0;
	
	vec4 color = mix(color_dark, color_bright, illumination);
	
	COLOR = texture(TEXTURE, UV) * color;
}