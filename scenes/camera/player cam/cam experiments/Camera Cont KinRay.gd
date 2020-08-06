extends Spatial


###Camera Variables
var camera 						#stores camera node location
var camera_angle = 0 			#stores camera up/down rotation
var camera_starting_angle = 60
var mouse_sensitivity = 0.3
var camera_change = Vector2()
var camera_rotation = Vector2()
var camera_angle_lim = 74
var correction_distance = 2
var camera_colliding


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
	
	if !camera_colliding:
		raycast_collision_correction()
	
	###Camera Rotating
	rotate_camera()


func camera_collision_correction():
	#Store pivot, current camera, and default camera locations
	var focus_location = $Pivot.get_global_transform().origin
	var camera_location = $Pivot/Camera.get_global_transform().origin
	var camera_location_default = $Pivot/camera_position_default.get_global_transform().origin
	
	#Calculate distance from camera to pivot
	var focus_distance = camera_location.distance_to(focus_location)
	var focus_direction = camera_location_default.direction_to(focus_location)
	var camera_slide_vector = focus_distance * focus_direction
	
	#Calculate distance from camera to default camera position
	var default_location_direction = camera_location.direction_to(camera_location_default)
	var default_location_distance = camera_location.distance_to(camera_location_default)
	camera_slide_vector = default_location_distance * default_location_direction
	
	#Test for collision behind camera
	var collision = $Pivot/camera_collision.move_and_collide(camera_slide_vector, true, true, true)
	
	if collision:
		#Move camera to collision point
		camera_slide_vector = collision.travel + (focus_direction * correction_distance)
		$Pivot/camera_collision.global_translate(camera_slide_vector)
		$Pivot/Camera.global_translate(camera_slide_vector)
		camera_colliding = true
	else:
		#Move camera to default position
		$Pivot/camera_collision.global_translate(camera_slide_vector)
		$Pivot/Camera.global_translate(camera_slide_vector)
		camera_colliding = false
		
	#Update camera position
	camera_location = $Pivot/Camera.get_global_transform().origin
		
	collision = null


func raycast_collision_correction():
	var move = Vector3()
	var move_point = Vector3()
	var camera_location = $Pivot/Camera.get_global_transform().origin
	var camera_location_default = $Pivot/camera_position_default.get_global_transform().origin
	var focus_point = $Pivot.get_global_transform().origin
	var focus_direction = camera_location_default.direction_to(focus_point)
	
	###Camera Collision Correction
	"Gets collision point of raycast and moves a distance of (focus_direction * wall_distance_modifier)"
	"in front of it"
	if $Pivot/camera_raycast.enabled and $Pivot/camera_raycast.is_colliding():
		var raycast_collision_point = $Pivot/camera_raycast.get_collision_point()
		var raycast_collision_distance = camera_location_default.distance_to(raycast_collision_point)
		move = (raycast_collision_distance * focus_direction) + (focus_direction * correction_distance)
		$Pivot/camera_collision.global_translate(move)
		$Pivot/Camera.global_translate(move)


func rotate_camera():
	if camera_change.length() > 0:
		self.rotate_y(deg2rad(-camera_change.x * mouse_sensitivity))
	
		var change = camera_change.y * mouse_sensitivity
		if change + camera_angle < camera_angle_lim and change + camera_angle > -camera_angle_lim:
			$Pivot.rotate_x(deg2rad(change))
			camera_angle += change
		camera_change = Vector2()

