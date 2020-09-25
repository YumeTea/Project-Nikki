extends Spatial

var rotate_speed = 1 #in degrees
var rotate = false

func _process(delta):
	if rotate:
		rotation_degrees.y -= rotate_speed
		rotation_degrees.y = bound_angle(rotation_degrees.y)


func _on_Timer_timeout():
	rotate = false
	$Tween.interpolate_property(self, "rotation_degrees", rotation_degrees, Vector3(rotation_degrees.x, -90, 0.0), 0.25, Tween.TRANS_CUBIC, Tween.EASE_OUT)	
	$Tween.start()


func bound_angle(angle):
	if angle < -270:
		angle += 360
	if angle > 90:
		angle -= 360
	
	return angle

