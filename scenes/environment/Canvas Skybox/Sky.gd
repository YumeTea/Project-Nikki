tool
extends Sprite


const screen_size = Vector2(1600, 900)
var fov = Vector2(70, 0)
const aspect_ratio = Vector2(16.0, 9.0)
const camera_rotation_limit_y = 88 #Max camera angle allowed +/-

var camera_rotation = Vector2()


func _ready():
	resize_sky_texture()


func resize_sky_texture():
	position = Vector2(0.0, 0.0)
	scale = Vector2(1.0, 1.0)
	fov.y = (fov.x / aspect_ratio.x) * aspect_ratio.y
	
	var view_angle_max = Vector2()
	view_angle_max.x = 360
	view_angle_max.y = ((2 * camera_rotation_limit_y))
	
	var sky_size
	var texture_size = texture.get_size()
	#Resizes base sprite texture to fill the field of view
	var rescale_texture = screen_size / texture_size
	set_scale(rescale_texture) #Texture size now equals screen size
	
	#Resize/reposition sprite to fill entire sky
	rescale_texture.x = rescale_texture.x * ((view_angle_max.x + fov.x) / (fov.x * 2.0))
	rescale_texture.y = rescale_texture.y * ((view_angle_max.y + fov.y) / (fov.y * 2.0))
	set_scale(rescale_texture)
	
	sky_size = texture_size * scale
	
	position.y -= ((texture_size.y * rescale_texture.y) / 2.0) - (screen_size.y / 2.0)

	material.set_shader_param("fov", fov)
	material.set_shader_param("sky_size", sky_size)
	material.set_shader_param("pi", PI)
