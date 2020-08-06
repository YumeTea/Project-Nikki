tool
extends AnimatedSprite


const screen_size = Vector2(1600, 900)
var sky_size = Vector2()
var fov = Vector2(70, 0)
const aspect_ratio = Vector2(16.0, 9.0)
const camera_rotation_limit_y = 88 #Max camera angle allowed +/-

var camera_rotation = Vector2()


#func _ready():
#	position = Vector2(850.0, 211.0)


func _process(_delta):
		position_sprite()


func position_sprite():
	fov.y = (fov.x / aspect_ratio.x) * aspect_ratio.y
	
	var view_angle_max = Vector2()
	view_angle_max.x = 360
	view_angle_max.y = ((2 * camera_rotation_limit_y))
	
	#Resize/reposition sprite to fill entire sky
	sky_size.x = screen_size.x * ((view_angle_max.x + fov.x) / (fov.x * 2.0))
	sky_size.y = screen_size.y * ((view_angle_max.y + fov.y) / (fov.y * 2.0))
	
	material.set_shader_param("sky_size", sky_size)

