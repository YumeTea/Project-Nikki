shader_type canvas_item;


uniform float 	aspect_ratio = 0.5;
uniform vec2 cam_rotation = vec2(0.0, 0.0);

const vec2 screen_size = vec2(1600, 900);
uniform vec2 fov;
uniform vec2 texture_size;
uniform vec2 sky_size;


void vertex() {
	vec2 vertex_offset = VERTEX;
	vertex_offset.x -= ((cam_rotation.x / (360.0)) * sky_size.x) - 1285.0;
	vertex_offset.y -= ((cam_rotation.y / (176.0)) * sky_size.y) + 15.0;
	VERTEX = vertex_offset;
}