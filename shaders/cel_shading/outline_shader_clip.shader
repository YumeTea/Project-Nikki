shader_type spatial;
render_mode unshaded, cull_front;

uniform vec4 outline_color : hint_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float outline_width : hint_range (0.0, 10.0, 1.0) = 1.0; //in pixels?


void vertex() {
	//convert from object space to view space to clip space (clip space is how the vertex would be on a 2D screen)
	
	//vertex in clip space; fourth parameter "w" is perspective correcting skew
	vec4 clip_position = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)); 
	//normal in clip space; fourth parameter discarded for normal; normals now in 2d clip space
	vec3 clip_normal = mat3(PROJECTION_MATRIX) * (mat3(MODELVIEW_MATRIX) * NORMAL);
	
	//expands outline in normal direction; double offset because conversion to NDC will have twice the range
	//multiply by clip_position.w to cancel shift in perspective going into NDC
	vec2 offset = normalize(clip_normal.xy) / VIEWPORT_SIZE * clip_position.w * outline_width * 2.0; 
	
	clip_position.xy += offset;
	
	POSITION = clip_position;
}


void fragment() {
	ALBEDO = outline_color.rgb;
}













