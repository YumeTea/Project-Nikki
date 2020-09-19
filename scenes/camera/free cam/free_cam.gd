extends Spatial

"""
Free cam movement limiter has issues at y_angle == PI/2 and -PI/2
"""

signal free_cam_position_changed(free_cam_position)


#Node Storage
var Player = null

#Camera Movement Variables
var track_speed = 1.0

#Camera Tracking Variables
var free_cam_mode = "player"
var free_cam_transform = Transform()
var player_cam_transform = Transform()

#Camera Flags
export var faded_out = false
var view_obscured


func _process(delta):
	if not Player:
		if Global.Player:
			Player = Global.Player
			Player.get_node("Camera_Rig").connect("camera_moved", self, "_on_camera_moved")
			Player.get_node("Camera_Rig").connect("view_blocked", self, "_on_view_blocked")
	
	if free_cam_mode == "player":
		player_camera()


func player_camera():
	global_transform = player_cam_transform
	emit_signal("free_cam_position_changed", global_transform.origin)


func player_camera_old():
	var move = player_cam_transform.origin - global_transform.origin
	var rotate
	
	var move_factor = 1.0
	
	#Camera Movement Limiting
	if move.length() > track_speed:
		move_factor = track_speed / move.length() #if limiting movement, calc a factor to limit rotation too
		
	move *= move_factor
	
	global_transform.origin += move
	
	rotate = player_cam_transform.basis.get_rotation_quat().get_euler() - global_transform.basis.get_rotation_quat().get_euler()
	rotate.y = bound_angle(rotate.y) * move_factor
	global_transform = global_transform.rotated(Vector3(0,1,0), rotate.y)
	
	var y_angle = transform.basis.get_rotation_quat().get_euler().y
	
	rotate = player_cam_transform.basis.get_rotation_quat().get_euler() - global_transform.basis.get_rotation_quat().get_euler()
	if y_angle >= PI/2.0 or y_angle <= -PI/2.0:
		rotate.x = -bound_angle(rotate.x) * move_factor
	else:
		rotate.x = bound_angle(rotate.x) * move_factor
	global_transform = global_transform.rotated(Vector3(1,0,0), rotate.x)
	
	rotate = player_cam_transform.basis.get_rotation_quat().get_euler() - global_transform.basis.get_rotation_quat().get_euler()
	if y_angle >= PI/2.0 or y_angle <= -PI/2.0:
		rotate.z = -bound_angle(rotate.z) * move_factor
	else:
		rotate.z = bound_angle(rotate.z) * move_factor
	global_transform = global_transform.rotated(Vector3(0,0,1), rotate.z)
	
	emit_signal("free_cam_position_changed", global_transform.origin)


func bound_angle(angle):
	#Angle > 180
	if (angle >= deg2rad(180)):
		angle = angle - deg2rad(360)
	#Angle < -180
	if (angle <= deg2rad(-180)):
		angle = angle + deg2rad(360)
	
	return angle


func _on_view_blocked(is_obscured):
	view_obscured = is_obscured


func _on_camera_moved(player_camera_transform):
	player_cam_transform = player_camera_transform














