shader_type spatial;

render_mode unshaded, cull_front;

uniform float thickness : hint_range (0, 1, 0.001) = 0.02;
uniform vec4 outline_color : hint_color = vec4(0.0, 0.0, 0.0, 1.0);


void vertex() {
	VERTEX += (NORMAL * thickness);
}


void fragment() {
	ALBEDO = outline_color.rgb;
	ALPHA = outline_color.a; //ALPHA value affects shadow that is drawn
}


