shader_type canvas_item;


uniform float 	aspect_ratio = 0.5;
uniform vec2 cam_rotation = vec2(0.0, 0.0); //cam_rotation is in degrees

const vec2 screen_size = vec2(1600, 900);
uniform vec2 fov; //fov is in degrees
uniform float pi = 3.14159265;
uniform vec2 sky_size;


//Sky should be rescaled before shader takes effect
void fragment() {
	vec2 sky_uv_offset = UV;
	vec2 fov_center_offset;
	
	//Distance from left side of fov to center in degrees
	fov_center_offset.x = ((fov.x / 1.2) / 360.0);
	//Distance from top side of fov to center in degrees
	fov_center_offset.y = ((fov.y / 1.2) / 180.0);
	
	//Link camera rotation to UVs
	//Camera y rotation scrolling
	sky_uv_offset.x = UV.x + (cam_rotation.x / (360.0));
	if (sky_uv_offset.x > 1.0) {
		sky_uv_offset.x -= 1.0;
	}
	//Camera x rotation scrolling
	sky_uv_offset.y = UV.y + (cam_rotation.y / (176.0 + (fov.y / 2.0)));
	
	//Pseudo sphere sky canvas calculations
	//(sky_uv_offset.x - fov_center_offset.x - (cam_rotation.x / (360.0))) puts sky_uv_offset.x == 0.0 at viewport center
	//(cos((sky_uv_offset.x - fov_center_offset.x - (cam_rotation.x / (360.0))) * 2.0 * pi))
//	sky_uv_offset.y -= (abs(cos((sky_uv_offset.x - fov_center_offset.x - (cam_rotation.x / (360.0))) * 2.0 * pi)) * cos(sky_uv_offset.y * pi)) / (fov.y / 2.0);
//	sky_uv_offset.y -= (abs(sin((sky_uv_offset.x - fov_center_offset.x - (cam_rotation.x / (360.0))) * pi)));
	
	
	
	
	
	// * ((cos((sky_uv_offset.y * pi))))
	
	
	sky_uv_offset.x += (abs(cos(sky_uv_offset.y * pi))) * (sin((sky_uv_offset.x - fov_center_offset.x - (cam_rotation.x / (360.0))) * 2.0 * pi) / 2.0);
	
	
	
	
	
	COLOR = texture(TEXTURE, sky_uv_offset);
}