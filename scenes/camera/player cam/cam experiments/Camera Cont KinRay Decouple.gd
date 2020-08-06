extends Spatial


signal camera_moved(camera_transform)
signal camera_direction_changed(direction)
signal view_blocked(is_obscured)


###Camera Variables
onready var camera = $Pivot/Camera_Position						#stores camera node location
var camera_angle = 0 			#stores camera up/down rotation
var camera_starting_angle = 15
var camera_angle_lim = 74
var camera_location
var camera_rotation = Vector2()
var camera_location_default
var focus_object
var focus_location
var focus_direction
var correction_distance = 1

#Mouse Variables
var mouse_sensitivity = 0.3
var mouse_change = Vector2()

#Joystick Variables
var right_joystick_axis = Vector2()
var joystick_deadzone = 0.1
var joystick_sensitivity = 1.5

#Centering Variables
var centering_turn_radius = deg2rad(25)
var centering_time = 6 #in frames
var centering_time_left
var facing_angle_x
var camera_angle_x
var rotate_angle_x
var facing_angle_y
var camera_angle_y
var rotate_angle_y
var focus_object_position

#Targetting Variables
var is_targetting = false

#Camera Flags
var is_obscured
var centered = false
var centering = false


func _ready():
	right_joystick_axis.y = camera_starting_angle
	rotate_camera(right_joystick_axis)
	right_joystick_axis.y = 0
	
	
	#Initial values for displays/targetting
	camera_location_default = $Pivot/Camera_Position_Default.get_global_transform().origin
	focus_location = $Pivot.get_global_transform().origin
	focus_direction = camera_location_default.direction_to(focus_location)
	
	emit_signal("camera_moved", camera.get_global_transform())
	emit_signal("camera_direction_changed", focus_direction)


func _process(delta):
	look()


func _input(event):
	get_right_joystick_input(event)
	if Input.is_action_pressed("center_view"):
		if centering == false:
			centering_time_left = centering_time
		centering = true
	else:
		set_recenter()
		centering = false
	
	if Input.is_action_just_pressed("lock_target") and centering == true:
		set_recenter()
		
		
	if Input.is_action_just_pressed("print_to_console") and event.get_device() == 0:
		print($Pivot/Camera_Position.get_global_transform().origin)


func look():
	if !centering:
		#Rotate camera
		rotate_camera(right_joystick_axis)
	else:
		center_camera()
	
	#Move camera to default position before testing view obstruction
	move_camera_to_pivot()
	
	#Run ray collision first
#	raycast_collision_correction()
	
	#Run camera collision second
	camera_collision_correction()
	
	#Tell free camera if default view is obscured
	if is_obscured:
		emit_signal("view_blocked", is_obscured)
	#Tell free camera that camera position has moved
	emit_signal("camera_moved", camera.get_global_transform())
	emit_signal("camera_direction_changed", focus_direction)


func move_camera_to_default():
	camera_location = camera.get_global_transform().origin
	camera_location_default = $Pivot/Camera_Position_Default.get_global_transform().origin
	
	#Calculate distance from camera to default camera position
	var default_location_direction = camera_location.direction_to(camera_location_default)
	var default_location_distance = camera_location.distance_to(camera_location_default)
	var camera_translation = default_location_distance * default_location_direction
	
	#Move camera to default position
	$Pivot/Camera_Collision.global_translate(camera_translation)
	$Pivot/Camera_Position.global_translate(camera_translation)


func move_camera_to_pivot():
	camera_location = camera.get_global_transform().origin
	focus_location = $Pivot.get_global_transform().origin
	
	#Calculate distance from camera to default camera position
	var focus_location_direction = camera_location.direction_to(focus_location)
	var focus_location_distance = camera_location.distance_to(focus_location)
	var camera_translation = focus_location_distance * focus_location_direction
	
	#Move camera to default position
	$Pivot/Camera_Collision.global_translate(camera_translation)
	$Pivot/Camera_Position.global_translate(camera_translation)


func raycast_collision_correction():
	var move = Vector3()
	var move_point = Vector3()
	var camera_location = camera.get_global_transform().origin
	var camera_location_default = $Pivot/Camera_Position_Default.get_global_transform().origin
	var focus_point = $Pivot.get_global_transform().origin
	var focus_direction = camera_location_default.direction_to(focus_point)
	
	###Camera Collision Correction
	"Gets collision point of raycast and moves a distance of (focus_direction * wall_distance_modifier)"
	"in front of it"
	if $Pivot/Camera_Raycast.enabled and $Pivot/Camera_Raycast.is_colliding():
		var raycast_collision_point = $Pivot/Camera_Raycast.get_collision_point()
		#Get distance from default camera position to raycast collision
		var raycast_collision_distance = camera_location_default.distance_to(raycast_collision_point)
		#Move the camera by said distance
		move = (raycast_collision_distance * focus_direction) + (focus_direction * correction_distance)
		$Pivot/Camera_Collision.global_translate(move)
		camera.global_translate(move)
		
		is_obscured = true
	else:
		is_obscured = false



func camera_collision_correction():
	#Store pivot, current camera, and default camera locations
	focus_location = $Pivot.get_global_transform().origin
	camera_location = camera.get_global_transform().origin
	camera_location_default = $Pivot/Camera_Position_Default.get_global_transform().origin
	
	#Calculate distance from camera to pivot
	var focus_distance = camera_location.distance_to(focus_location)
	focus_direction = camera_location_default.direction_to(focus_location)
	var camera_slide_vector = focus_distance * focus_direction
	
	#Calculate distance from camera to default camera position
	var default_location_direction = camera_location.direction_to(camera_location_default)
	var default_location_distance = camera_location.distance_to(camera_location_default)
	camera_slide_vector = default_location_distance * default_location_direction
	
	#Test for collision behind camera
	var collision = $Pivot/Camera_Collision.move_and_collide(camera_slide_vector, true, true, true)
	
	if collision:
		#Check if camera would move past pivot point
		camera_slide_vector = collision.travel + (focus_direction * correction_distance)
		print(collision.travel.length())
		#Move camera to collision point
		$Pivot/Camera_Collision.global_translate(camera_slide_vector)
		$Pivot/Camera_Position.global_translate(camera_slide_vector)
		is_obscured = true
	else:
		#Move camera to default position
		$Pivot/Camera_Collision.global_translate(camera_slide_vector)
		$Pivot/Camera_Position.global_translate(camera_slide_vector)
		is_obscured = false
		
	#Update camera position
	camera_location = camera.get_global_transform().origin
		
	collision = null


func rotate_camera(input_change):
	if input_change.length() > 0:
		self.rotate_y(deg2rad(-input_change.x))
		
		var change = input_change.y
		if change + camera_angle < camera_angle_lim and change + camera_angle > -camera_angle_lim:
			$Pivot.rotate_x(deg2rad(change))
			camera_angle += change


func center_camera():
	var facing_direction
	var target_direction
	
	###Set y facing angle based on direction to target
	if is_targetting == true:
		target_direction = self.get_global_transform().origin.direction_to(focus_object.get_global_transform().origin)
		facing_angle_y = calculate_global_y_rotation(target_direction)
	else:
		facing_angle_y = owner.get_node("Rig").get_global_transform().basis.get_euler().y
	##Y angle to target calculation
	camera_angle_y = self.get_global_transform().basis.get_euler().y
	
	###Y Centering
	if !centered:
		###Left/Right Re-Centering
		if centering_time_left == centering_time:
			#Calculate y rotation angle before dividing it for centering
			rotate_angle_y = (facing_angle_y - camera_angle_y)
			#Turning left at degrees > 180
			if (rotate_angle_y > deg2rad(180)):
				rotate_angle_y = rotate_angle_y - deg2rad(360)
			#Turning right at degrees < -180
			if (rotate_angle_y < deg2rad(-180)):
				rotate_angle_y = rotate_angle_y + deg2rad(360)
			
			rotate_angle_y = rotate_angle_y/centering_time
		
		###Y Rotation
		self.rotate_y(rotate_angle_y)
	else:
		#Just move to facing angle if center point reached
		rotate_angle_y = (facing_angle_y - camera_angle_y)
		self.rotate_y(rotate_angle_y)
		
	###Set x facing angle based on direction to target
	if is_targetting == true:
		target_direction = $Pivot.get_global_transform().origin.direction_to(focus_object.get_global_transform().origin)
		facing_angle_x = calculate_local_x_rotation(target_direction) + deg2rad(camera_starting_angle)
	else:
		facing_angle_x = owner.get_node("Rig").get_global_transform().basis.get_euler().x + deg2rad(camera_starting_angle)
	##X angle to target calculation
	camera_angle_x = $Pivot.get_global_transform().basis.get_euler().x
	
	###X Centering
	if !centered:
		###Up/Down Re-Centering
		if centering_time_left == centering_time:
			#Calculate x rotation angle before dividing it for centering
			rotate_angle_x = (facing_angle_x - camera_angle_x)
			#Looking down at greater than camera_angle_lim
			if (rotate_angle_x > deg2rad(camera_angle_lim)):
				rotate_angle_x = rotate_angle_x - deg2rad(360)
			##Looking up at greater than =-camera_angle_lim
			if (rotate_angle_x < deg2rad(-camera_angle_lim)):
				rotate_angle_x = rotate_angle_x + deg2rad(360)
				
			rotate_angle_x = rotate_angle_x/centering_time
		
		###X Rotation
		$Pivot.rotate_x(rotate_angle_x)
	else:
		#Just move to facing angle if center point reached
		rotate_angle_x = (facing_angle_x - camera_angle_x)
		$Pivot.rotate_x(rotate_angle_x)
		
	###Decrement Timer
	centering_time_left -= 1
	if centering_time_left <= 0:
		camera_angle = 0
		centered = true

func calculate_global_y_rotation(direction):
	var test_direction = Vector2(0,1)
	var direction_to = Vector2(direction.x, direction.z)
	var y_rotation = -test_direction.angle_to(direction_to)
	return y_rotation #Output is PI > y > -PI


func calculate_local_x_rotation(direction):
	var test_direction = Vector3(direction.x, 0, direction.z)
	var x_rotation
	
	if direction.y < 0:
		x_rotation = test_direction.angle_to(direction)
	else:
		x_rotation = -test_direction.angle_to(direction)
	
	return x_rotation


func get_right_joystick_input(event):
	if event is InputEventJoypadMotion and event.get_device() == 0:
		if event.get_axis() == 2:
			if event.get_axis_value() < joystick_deadzone and event.get_axis_value() > -joystick_deadzone:
				right_joystick_axis.x = 0
			else:
				right_joystick_axis.x = event.get_axis_value() * joystick_sensitivity
		if event.get_axis() == 3:
			if event.get_axis_value() < joystick_deadzone and event.get_axis_value() > -joystick_deadzone:
				right_joystick_axis.y = 0
			else:
				right_joystick_axis.y = event.get_axis_value() * joystick_sensitivity


func set_recenter():
	centered = false
	centering_time_left = centering_time


func _on_Nikkiv2_focus_target(target_pos_node):
	if target_pos_node:
		focus_object = target_pos_node
		is_targetting = true
	else:
		focus_object = target_pos_node
		is_targetting = false
		set_recenter()




