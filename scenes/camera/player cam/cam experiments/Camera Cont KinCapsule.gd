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

#Calculation Values
var default_location_direction
var default_location_distance
onready var focus_location = $Pivot.get_global_transform().origin
onready var camera_location = $Pivot/Camera.get_global_transform().origin
onready var camera_location_default = $Pivot/Camera_default_loc.get_global_transform().origin
var focus_distance
var focus_direction
var camera_slide_vector
var collision


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
	#Calculate distance from camera to default camera position
	default_location_direction = camera_location.direction_to(camera_location_default)
	default_location_distance = camera_location.distance_to(camera_location_default)
	camera_slide_vector = default_location_distance * default_location_direction
	
	#Move camera to default position
	$Pivot/camera_collision.global_translate(camera_slide_vector)
	$Pivot/Camera.global_translate(camera_slide_vector)
	
	#Store pivot, current camera, and default camera locations
	focus_location = $Pivot.get_global_transform().origin
	camera_location = $Pivot/Camera.get_global_transform().origin
	camera_location_default = $Pivot/Camera_default_loc.get_global_transform().origin
	
	#Calculate distance from camera to pivot
	focus_distance = camera_location.distance_to(focus_location)
	focus_direction = camera_location_default.direction_to(focus_location)
	camera_slide_vector = focus_distance * focus_direction
	
	#Test for collision in front of camera
	collision = $Pivot/camera_collision.move_and_collide(camera_slide_vector, true, true, true)
	print(collision)
	if collision:
		#Move camera collision and camera to pivot
		$Pivot/camera_collision.global_translate(camera_slide_vector)
		$Pivot/Camera.global_translate(camera_slide_vector)
		#See how far from pivot to move camera
		collision = $Pivot/camera_collision.move_and_collide(-camera_slide_vector, true, true, true)
		camera_slide_vector = collision.travel + (focus_direction * correction_distance) #distance travelled before collision
		
		#Move camera to collision point
		$Pivot/camera_collision.global_translate(camera_slide_vector)
		$Pivot/Camera.global_translate(camera_slide_vector)
		
		#Update camera position
		camera_location = $Pivot/Camera.get_global_transform().origin
	else:
		#Calculate distance from camera to default camera position
		default_location_direction = camera_location.direction_to(camera_location_default)
		default_location_distance = camera_location.distance_to(camera_location_default)
		camera_slide_vector = default_location_distance * default_location_direction
	
		#Test for collision behind camera
		collision = $Pivot/camera_collision.move_and_collide(camera_slide_vector, true, true, true)
	
		if collision:
			#Move camera to collision point
			camera_slide_vector = collision.travel + (focus_direction * correction_distance)
			$Pivot/camera_collision.global_translate(camera_slide_vector)
			$Pivot/Camera.global_translate(camera_slide_vector)
		else:
			#Move camera to default position
			$Pivot/camera_collision.global_translate(camera_slide_vector)
			$Pivot/Camera.global_translate(camera_slide_vector)
		
		#Update camera position
		camera_location = $Pivot/Camera.get_global_transform().origin
		
	#Reset camera collision storage
	collision = null


func rotate_camera():
	if camera_change.length() > 0:
		self.rotate_y(deg2rad(-camera_change.x * mouse_sensitivity))
	
		var change = camera_change.y * mouse_sensitivity
		if change + camera_angle < camera_angle_lim and change + camera_angle > -camera_angle_lim:
			$Pivot.rotate_x(deg2rad(change))
			camera_angle += change
		camera_change = Vector2()

