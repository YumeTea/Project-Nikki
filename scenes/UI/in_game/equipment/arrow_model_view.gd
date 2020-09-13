extends Spatial

var rotate_speed = 1 #in degrees

func _process(delta):
	rotation_degrees.y -= rotate_speed
