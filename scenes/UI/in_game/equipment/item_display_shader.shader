shader_type canvas_item;

uniform sampler2D background_texture : hint_albedo;

uniform vec4 text_color : hint_color;
uniform vec4 background_color : hint_color;
uniform vec4 border_color : hint_color;


void fragment() {
//	//Draw raw background first
//	COLOR = texture(background_texture, UV);
	
//	//Draw background
//	if (COLOR.b == 1.0)
//		COLOR = background_color;
	
	//Draw text
//	if (COLOR == background_color)
//		if (texture(viewport_texture, UV).a > 0.0)
//			COLOR = texture(viewport_texture, UV);
	
//	//Draw border
//	if (COLOR.g == 1.0)
//		COLOR = border_color;
}




