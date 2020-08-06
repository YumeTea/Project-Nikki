extends Spatial


###Camera Variables
var camera 						#stores camera node location
var camera_angle = 0 			#stores camera up/down rotation
var camera_starting_angle = 60
var mouse_sensitivity = 0.3
var camera_change = Vector2()
var camera_rotation = Vector2()
var camera_angle_lim = 74
var correction_distance = 1


func _ready():
	camera_change.y += camera_starting_angle
	rotate_camera()



func _process(delta):
	look()


func _input(event):
	#Checks if player input event is the mouse moving
	#Set camera_change to value of mouse position relative to the previous position
	if event is InputEventMouseMotion:
		camera_change = event.relative


func look():
	###Collision Detection
	camera_collision_correction()
	
	###Camera Rotating
	rotate_camera()


func camera_collision_correction():
	var move = Vector3()
	var camera_location = $Pivot/Camera.get_global_transform().origin
	var camera_location_default = $Pivot/Camera_default_loc.get_global_transform().origin
	var focus_direction = Vector3()
	var move_point = Vector3()
	var focus_point = self.get_global_transform().origin
	var camera_collision_point = $Pivot/camera_raycast.get_collision_point()
	
	###Camera Collision Correction
	"Gets collision point of raycast and moves a distance of (focus_direction * wall_distance_modifier)"
	"in front of it"
	if $Pivot/camera_raycast.enabled and $Pivot/camera_raycast.is_colliding():
		focus_direction = camera_location_default.direction_to(focus_point)
		move_point = camera_collision_point + (focus_direction * correction_distance)
		move = (move_point - camera_location)
		$Pivot/Camera.global_translate(move)
	else:
		focus_direction = camera_location_default.direction_to(focus_point)
		move_point = camera_location_default - focus_direction
		move = (move_point - camera_location)
		$Pivot/Camera.global_translate(move)


func rotate_camera():
	if camera_change.length() > 0:
		self.rotate_y(deg2rad(-camera_change.x * mouse_sensitivity))
	
		var change = camera_change.y * mouse_sensitivity
		if change + camera_angle < camera_angle_lim and change + camera_angle > -camera_angle_lim:
			$Pivot.rotate_x(deg2rad(change))
			camera_angle += change
		camera_change = Vector2()

