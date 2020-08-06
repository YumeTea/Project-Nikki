extends Spatial


signal camera_moved(camera_transform)
signal camera_direction_changed(direction)
signal view_locked(is_view_locked, centering_time_left)
signal view_blocked(is_obscured)

signal break_target

#Node Storage
onready var camera = $Pivot/Camera_Position
onready var pivot = $Pivot
onready var default_camera_position = $Pivot/Camera_Position_Default
onready var camera_collision = $Pivot/Camera_Collision

###Camera Variables
var camera_angle = Vector2() #stores camera global rotation
var camera_starting_angle = Vector2(deg2rad(15), deg2rad(0))
var camera_angle_lim = Vector2(deg2rad(74), deg2rad(45))
var camera_location
var camera_rotation = Vector2()
var camera_location_default
var focus_object
var focus_location
#var focus_direction
var correction_distance = 1

#Joystick Variables
var right_joystick_axis = Vector2()
var joystick_deadzone = 0.1
var joystick_sensitivity = 3 #look sensetivity for npc

#Centering Variables
var centering_turn_radius = deg2rad(25)
var centering_time = 6 #in frames
var centering_time_left
var current_camera_angle = Vector2()
var rotate_angle = Vector2()
var focus_object_position

#Targetting Variables
var is_targetting = false

#Camera Flags
var is_obscured
var centered = false
var centering = false
var view_locked = false



#Head Variables
var facing_direction = Vector3()
var previous_facing_angle = Vector2()
var focus_direction = Vector2()
var focus_angle = Vector2()
var focus_angle_global = Vector2()
var focus_starting_angle = Vector2(deg2rad(15), deg2rad(0))
var focus_angle_lim = Vector2(deg2rad(74), deg2rad(82))

var body_turn_angle = Vector2()



func _ready():
#	#Move camera to initial rotation
#	right_joystick_axis = camera_starting_angle
#	rotate_camera(right_joystick_axis)
#	right_joystick_axis = Vector2(0,0)
#
#	#Set initial camera rotation
#	camera_angle = camera_starting_angle
	
	###Head Value Initialization
	right_joystick_axis.x = rad2deg(focus_starting_angle.y)
	right_joystick_axis.y = rad2deg(focus_starting_angle.x)
	rotate_camera(right_joystick_axis)
	right_joystick_axis = Vector2(0,0)
	
	
	focus_angle = focus_starting_angle
	facing_direction = get_node_direction(owner.get_node("Rig"))
	previous_facing_angle.y = calculate_global_y_rotation(facing_direction)
	previous_facing_angle.x = calculate_local_x_rotation(facing_direction)
	
	#Initial values for displays/targetting
	camera_location_default = $Pivot/Camera_Position_Default.get_global_transform().origin
	focus_location = $Pivot.get_global_transform().origin
	focus_direction = camera_location_default.direction_to(focus_location)
	
	emit_signal("camera_moved", camera.get_global_transform())
	emit_signal("camera_direction_changed", focus_direction)


func _input(event):
	get_right_joystick_input(event)
	if Input.is_action_pressed("center_view"):
		view_locked = true
		centering = true
		if event.is_action_pressed("center_view") and event.get_device() == 0:
			centered = false
			reset_recenter()
		emit_signal("view_locked", view_locked, centering_time_left)
	if event.is_action_released("center_view") and event.get_device() == 0:
		view_locked = false
		centering = false
		emit_signal("view_locked", view_locked, centering_time_left)
	
	if event.is_action_pressed("lock_target") and event.get_device() == 0:
		reset_recenter()


func _process(delta):
	look()


func look():
	if !centering and !is_targetting:
		rotate_camera(right_joystick_axis)
	else:
		center_camera()

	camera_collision_correction(camera, pivot, default_camera_position, camera_collision)
	
	previous_facing_angle.y = calculate_global_y_rotation(get_node_direction(owner.get_node("Rig")))
	previous_facing_angle.x = calculate_local_x_rotation(get_node_direction(owner.get_node("Rig")))
	
	#Tell free camera if default view is obscured
	if is_obscured:
		emit_signal("view_blocked", is_obscured)
	#Tell free camera that camera position has moved
	emit_signal("camera_moved", camera.get_global_transform())
	emit_signal("camera_direction_changed", focus_direction)

#func rotate_camera(input_change):
#	###Focus Input Handling
#	if input_change.length() > 0:
#		var angle_change = Vector2()
#
#		angle_change.y = deg2rad(-input_change.x)
#		if focus_angle.y + angle_change.y < focus_angle_lim.y and focus_angle.y + angle_change.y > -focus_angle_lim.y:
#			self.rotate_y(deg2rad(-input_change.x))
#
#		angle_change.x = deg2rad(input_change.y)
#		if focus_angle.x + angle_change.x < focus_angle_lim.x and focus_angle.x + angle_change.x > -focus_angle_lim.x:
#			$Pivot.rotate_x(deg2rad(input_change.y))
#			focus_angle.x += angle_change.x
#		else:
#			$Pivot.rotate_x((focus_angle_lim.x * sign(focus_angle.x)) - focus_angle.x)
#			focus_angle.x += ((focus_angle_lim.x * sign(focus_angle.x)) - focus_angle.x)


func rotate_camera(input_change):
	var focus_angle_change = Vector2(0,0)
	var turn_angle = Vector2()
	var facing_direction = get_node_direction(owner.get_node("Rig"))
	var facing_angle = Vector2()
	
	focus_direction = get_node_direction($Pivot)
	focus_angle_global.y = calculate_global_y_rotation(focus_direction)
	focus_angle_global.x = calculate_local_x_rotation(focus_direction)
	facing_angle.y = calculate_global_y_rotation(facing_direction)
	facing_angle.x = calculate_local_x_rotation(facing_direction)
	
	var facing_angle_change = Vector2()
	###Y Focus Angle Limiting
	facing_angle_change.y = previous_facing_angle.y - facing_angle.y
	#Turning left at degrees > 180
	if (facing_angle_change.y > deg2rad(180)):
		facing_angle_change.y = facing_angle_change.y - deg2rad(360)
	#Turning right at degrees < -180
	if (facing_angle_change.y < deg2rad(-180)):
		facing_angle_change.y = facing_angle_change.y + deg2rad(360)
		
	if(focus_angle.y + facing_angle_change.y) < focus_angle_lim.y and (focus_angle.y + facing_angle_change.y) > -focus_angle_lim.y:
		focus_angle.y += facing_angle_change.y
	else:
		focus_angle_change.y = (sign(focus_angle.y) * focus_angle_lim.y) - focus_angle.y
		focus_angle.y += focus_angle_change.y
		turn_angle.y = -facing_angle_change.y + focus_angle_change.y
			
		self.rotate_y(turn_angle.y)
	
	###X Focus Angle Limiting
	facing_angle_change.x = previous_facing_angle.x - facing_angle.x
	#Turning left at degrees > 180
	if (facing_angle_change.x > deg2rad(180)):
		facing_angle_change.x = facing_angle_change.x - deg2rad(360)
	#Turning right at degrees < -180
	if (facing_angle_change.x < deg2rad(-180)):
		facing_angle_change.x = facing_angle_change.x + deg2rad(360)
		
	if(focus_angle.x + facing_angle_change.x) < focus_angle_lim.x and (focus_angle.x + facing_angle_change.x) > -focus_angle_lim.x:
		focus_angle.x += facing_angle_change.x
	else:
		focus_angle_change.x = (sign(focus_angle.x) * focus_angle_lim.x) - focus_angle.x
		focus_angle.x += focus_angle_change.x
		turn_angle.x = -facing_angle_change.x + focus_angle_change.x
			
		$Pivot.rotate_y(turn_angle.x)
	
	###Focus Input Handling
	if input_change.length() > 0:
		var angle_change = Vector2()

		angle_change.y = deg2rad(-input_change.x)
		if focus_angle.y + angle_change.y < focus_angle_lim.y and focus_angle.y + angle_change.y > -focus_angle_lim.y:
			self.rotate_y(deg2rad(-input_change.x))
			focus_angle.y += angle_change.y
		else:
			self.rotate_y((focus_angle_lim.y * sign(focus_angle.y)) - focus_angle.y)
			focus_angle.y += ((focus_angle_lim.y * sign(focus_angle.y)) - focus_angle.y)

		angle_change.x = deg2rad(input_change.y)
		if focus_angle.x + angle_change.x < focus_angle_lim.x and focus_angle.x + angle_change.x > -focus_angle_lim.x:
			$Pivot.rotate_x(deg2rad(input_change.y))
			focus_angle.x += angle_change.x
		else:
			$Pivot.rotate_x((focus_angle_lim.x * sign(focus_angle.x)) - focus_angle.x)
			focus_angle.x += ((focus_angle_lim.x * sign(focus_angle.x)) - focus_angle.x)


#func rotate_camera_tank_style(input_change):
#	var next_focus_angle = Vector2()
#	var turn_angle = Vector2()
#	var facing_direction = get_node_direction(owner.get_node("Rig"))
#	var facing_angle = Vector2()
#
#	#Move head with body facing direction
#	facing_angle.y = calculate_global_y_rotation(facing_direction)
#	self.rotate_y(facing_angle.y - previous_facing_angle.y)
#	facing_angle.x = calculate_local_x_rotation(facing_direction)
#	$Pivot.rotate_x(facing_angle.x)
#
#	if input_change.length() > 0:
#		var angle_change = Vector2()
#
#		angle_change.y = deg2rad(input_change.x)
#		if focus_angle.y + angle_change.y < focus_angle_lim.y and focus_angle.y + angle_change.y > -focus_angle_lim.y:
#			self.rotate_y(deg2rad(-input_change.x))
#			focus_angle.y += angle_change.y
#		else:
#			self.rotate_y((focus_angle_lim.y * sign(focus_angle.y)) - focus_angle.y)
#			focus_angle.y += ((focus_angle_lim.y * sign(focus_angle.y)) - focus_angle.y)
#
#		angle_change.x = deg2rad(input_change.y)
#		if focus_angle.x + angle_change.x < focus_angle_lim.x and focus_angle.x + angle_change.x > -focus_angle_lim.x:
#			$Pivot.rotate_x(deg2rad(input_change.y))
#			focus_angle.x += angle_change.x
#		else:
#			$Pivot.rotate_x((focus_angle_lim.x * sign(focus_angle.x)) - focus_angle.x)
#			focus_angle.x += ((focus_angle_lim.x * sign(focus_angle.x)) - focus_angle.x)
#
#	previous_facing_angle.y = calculate_global_y_rotation(facing_direction)
#	previous_facing_angle.x = calculate_local_x_rotation(facing_direction)


func move_camera_to_default(camera, pivot, default_pos_node):
	camera_location = camera.get_global_transform().origin
	camera_location_default = default_pos_node.get_global_transform().origin
	
	#Calculate distance from camera to default camera position
	var default_location_direction = camera_location.direction_to(camera_location_default)
	var default_location_distance = camera_location.distance_to(camera_location_default)
	var camera_translation = default_location_distance * default_location_direction
	
	#Move camera to default position
	pivot.get_node("Camera_Collision").global_translate(camera_translation)
	camera.global_translate(camera_translation)


func move_camera_to_pivot(camera, pivot):
	camera_location = camera.get_global_transform().origin
	focus_location = pivot.get_global_transform().origin
	
	#Calculate distance from camera to default camera position
	var focus_location_direction = camera_location.direction_to(focus_location)
	var focus_location_distance = camera_location.distance_to(focus_location)
	var camera_translation = focus_location_distance * focus_location_direction
	
	#Move camera to default position
	pivot.get_node("Camera_Collision").global_translate(camera_translation)
	camera.global_translate(camera_translation)



func camera_collision_correction(camera, pivot, default_pos_node, camera_collision):
	#Moves camera to pivot point
	move_camera_to_pivot(camera, pivot)
	
	#Store pivot, current camera, and default camera locations
	focus_location = pivot.get_global_transform().origin
	camera_location = camera.get_global_transform().origin
	camera_location_default = default_pos_node.get_global_transform().origin
	
	#Calculate distance from camera to pivot
	var focus_distance = camera_location.distance_to(focus_location)
	focus_direction = camera_location_default.direction_to(focus_location)
	var camera_slide_vector = focus_distance * focus_direction
	
	#Calculate distance from camera to default camera position
	var default_location_direction = camera_location.direction_to(camera_location_default)
	var default_location_distance = camera_location.distance_to(camera_location_default)
	camera_slide_vector = default_location_distance * default_location_direction
	
	#Test for collision behind camera
	var collision = camera_collision.move_and_collide(camera_slide_vector, true, true, true)
	
	if collision:
		#Check if camera would move past pivot point
		camera_slide_vector = collision.travel + (focus_direction * correction_distance)

		#Move camera to collision point
		camera_collision.global_translate(camera_slide_vector)
		camera.global_translate(camera_slide_vector)
		is_obscured = true
	else:
		#Move camera to default position
		camera_collision.global_translate(camera_slide_vector)
		camera.global_translate(camera_slide_vector)
		is_obscured = false
		
	#Update camera position
	camera_location = camera.get_global_transform().origin
	focus_direction = camera_location.direction_to(focus_location)
		
	collision = null


func center_camera():
	var target_direction = Vector3()
	var target_angle = Vector2()
	var facing_angle = Vector2()
	var centering_angle = Vector2()
	var body_turn_angle = Vector2()
	
	#Centering time left is 0 when centered
	if centering_time_left <= 0:
		centered = true
	
	###Set y facing angle based on direction to target
	if is_targetting:
		#Get values for would be focus angle to check it
		var test_focus_angle = Vector2()
		facing_direction = get_node_direction(owner.get_node("Rig"))
		target_direction = self.get_global_transform().origin.direction_to(focus_object.get_global_transform().origin)

		facing_angle.y = calculate_global_y_rotation(facing_direction)
		facing_angle.x = calculate_local_x_rotation(facing_direction)
		target_angle.y = calculate_global_y_rotation(target_direction)
		target_angle.x = calculate_local_x_rotation(target_direction)
		
		###Calculate would be focus angle
		##Y focus angle correction
		test_focus_angle.y = target_angle.y - facing_angle.y
		#Focus angle y > 180
		if (test_focus_angle.y > deg2rad(180)):
			test_focus_angle.y = test_focus_angle.y - deg2rad(360)
		#Focus angle y < -180
		if (test_focus_angle.y < deg2rad(-180)):
			test_focus_angle.y = test_focus_angle.y + deg2rad(360)
		
		##X focus angle correction
		test_focus_angle.x = target_angle.x - facing_angle.x
		#Focus angle x > 180
		if (test_focus_angle.x > deg2rad(180)):
			test_focus_angle.x = test_focus_angle.x - deg2rad(360)
		#Focus angle x < -180
		if (test_focus_angle.x < deg2rad(-180)):
			test_focus_angle.x = test_focus_angle.x + deg2rad(360)
		
		#Check if would be focus angle is outside the focus angle limit
		if test_focus_angle.y > focus_angle_lim.y or test_focus_angle.y < -focus_angle_lim.y:
			is_targetting = false
			reset_recenter()
			emit_signal("break_target")
			return
		if test_focus_angle.x > focus_angle_lim.x or test_focus_angle.x < -focus_angle_lim.x:
			is_targetting = false
			reset_recenter()
			emit_signal("break_target")
			return
		
		#If turning the opposite direction of body, let body rotate and center on facing angle
		body_turn_angle = get_body_centering_angle(owner.get_node("Rig"))
		if sign(body_turn_angle.y) != sign(focus_angle.y):
			self.rotate_y(body_turn_angle.y)
		
		#Determine y direction for focus to rotate to
		if !centered and centering and sign(body_turn_angle.y) != sign(focus_angle.y):
			target_direction = get_node_direction(owner.get_node("Rig"))
		else:
			target_direction = self.get_global_transform().origin.direction_to(focus_object.get_global_transform().origin)
		centering_angle.y = calculate_global_y_rotation(target_direction)
	else:
		centering_angle.y = owner.get_node("Rig").get_global_transform().basis.get_euler().y
	
	##Y angle to target calculation
	current_camera_angle.y = self.get_global_transform().basis.get_euler().y
	
	###Y Centering
	if !centered:
		#Calculate y rotation angle before dividing it for centering
		rotate_angle.y = (centering_angle.y - current_camera_angle.y)
		#Turning left at degrees > 180
		if (rotate_angle.y > deg2rad(180)):
			rotate_angle.y = rotate_angle.y - deg2rad(360)
		#Turning right at degrees < -180
		if (rotate_angle.y < deg2rad(-180)):
			rotate_angle.y = rotate_angle.y + deg2rad(360)
		
		rotate_angle.y = rotate_angle.y/centering_time_left
			
		###Y Rotation
		focus_angle.y -= focus_angle.y/ centering_time_left
		self.rotate_y(rotate_angle.y)
	else:
		focus_angle.y = focus_starting_angle.y
		#Just move to facing angle if center point reached
		rotate_angle.y = (centering_angle.y - current_camera_angle.y)
		self.rotate_y(rotate_angle.y)
	
	
	###Set x facing angle based on direction to target
	#Determine x direction for focus to rotate to
	if is_targetting:
		target_direction = $Pivot.get_global_transform().origin.direction_to(focus_object.get_global_transform().origin)
		centering_angle.x = calculate_local_x_rotation(target_direction) + camera_starting_angle.x
	else:
		centering_angle.x = owner.get_node("Rig").get_global_transform().basis.get_euler().x + camera_starting_angle.x
	
	##X angle to target calculation
	current_camera_angle.x = $Pivot.get_global_transform().basis.get_euler().x
	
	###X Centering
	if !centered:
		#Calculate x rotation angle before dividing it for centering
		rotate_angle.x = (centering_angle.x - current_camera_angle.x)
		#Looking down at greater than focus_angle_lim.x
		if (rotate_angle.x > focus_angle_lim.x):
			rotate_angle.x = rotate_angle.x - deg2rad(360)
		##Looking up at greater than =-focus_angle_lim.x
		if (rotate_angle.x < -focus_angle_lim.x):
			rotate_angle.x = rotate_angle.x + deg2rad(360)
			
		rotate_angle.x = rotate_angle.x/centering_time_left
			
		###X Rotation
		focus_angle.x -= focus_angle.x/centering_time_left
		$Pivot.rotate_x(rotate_angle.x)
	
	else:
		focus_angle.x = focus_starting_angle.x
		#Just move to facing angle if center point reached
		rotate_angle.x = (centering_angle.x - current_camera_angle.x)
		$Pivot.rotate_x(rotate_angle.x)
	
	if is_targetting:
		#Calculate new focus angle
		facing_direction = get_node_direction(owner.get_node("Rig"))
		facing_angle.y = calculate_global_y_rotation(facing_direction)
		facing_angle.x = calculate_local_x_rotation(facing_direction)
		target_angle.y = calculate_global_y_rotation(target_direction)
		target_angle.x = calculate_local_x_rotation(target_direction)
		
		##Y focus angle correction
		focus_angle.y = target_angle.y - facing_angle.y
		#Focus angle y > 180
		if (focus_angle.y > deg2rad(180)):
			focus_angle.y = focus_angle.y - deg2rad(360)
		#Focus angle y < -180
		if (focus_angle.y < deg2rad(-180)):
			focus_angle.y = focus_angle.y + deg2rad(360)
		
		##X focus angle correction
		focus_angle.x = target_angle.x - facing_angle.x
		#Focus angle y > 180
		if (focus_angle.x > deg2rad(180)):
			focus_angle.x = focus_angle.x - deg2rad(360)
		#Focus angle y < -180
		if (focus_angle.x < deg2rad(-180)):
			focus_angle.x = focus_angle.x + deg2rad(360)
		
			#Check if rotated past focus_angle_lim and correct if so
			if focus_angle.y > focus_angle_lim.y or focus_angle.y < -focus_angle_lim.y:
				self.rotate_y(-(focus_angle.y - (focus_angle_lim.y * sign(focus_angle.y))))
				focus_angle.y -= focus_angle.y - (focus_angle_lim.y * sign(focus_angle.y))
				is_targetting = false
				reset_recenter()
				emit_signal("break_target")
			if focus_angle.x > focus_angle_lim.x or focus_angle.x < -focus_angle_lim.x:
				self.rotate_x(-(focus_angle.x - (focus_angle_lim.x * sign(focus_angle.x))))
				focus_angle.x -= focus_angle.x - (focus_angle_lim.x * sign(focus_angle.x))
				is_targetting = false
				reset_recenter()
				emit_signal("break_target")
	
	
	###Decrement Timer
	if centering_time_left > 0:
		centering_time_left -= 1

#func center_camera():
#	var target_direction
#	var target_angle
#	var centering_angle = Vector2()
#
#	if centering_time_left <= 0:
#		camera_angle.x = camera_starting_angle.x
#		centered = true
#
#	###Set y facing angle based on direction to target
#	if is_targetting:
#		target_direction = self.get_global_transform().origin.direction_to(focus_object.get_global_transform().origin)
#		centering_angle.y = calculate_global_y_rotation(target_direction)
#	else:
#		centering_angle.y = owner.get_node("Rig").get_global_transform().basis.get_euler().y
#	##Y angle to target calculation
#	current_camera_angle.y = self.get_global_transform().basis.get_euler().y
#
#	###Y Centering
#	if !centered:
#		###Left/Right Re-Centering
#		if centering_time_left == centering_time:
#			#Calculate y rotation angle before dividing it for centering
#			rotate_angle.y = (centering_angle.y - current_camera_angle.y)
#			#Turning left at degrees > 180
#			if (rotate_angle.y > deg2rad(180)):
#				rotate_angle.y = rotate_angle.y - deg2rad(360)
#			#Turning right at degrees < -180
#			if (rotate_angle.y < deg2rad(-180)):
#				rotate_angle.y = rotate_angle.y + deg2rad(360)
#
#			rotate_angle.y = rotate_angle.y/centering_time
#
#		###Y Rotation
#		self.rotate_y(rotate_angle.y)
#	else:
#		#Just move to facing angle if center point reached
#		rotate_angle.y = (centering_angle.y - current_camera_angle.y)
#		self.rotate_y(rotate_angle.y)
#
#	###Set x facing angle based on direction to target
#	if is_targetting:
#		target_direction = $Pivot.get_global_transform().origin.direction_to(focus_object.get_global_transform().origin)
#		centering_angle.x = calculate_local_x_rotation(target_direction) + camera_starting_angle.x
#	else:
#		centering_angle.x = owner.get_node("Rig").get_global_transform().basis.get_euler().x + camera_starting_angle.x
#	##X angle to target calculation
#	current_camera_angle.x = $Pivot.get_global_transform().basis.get_euler().x
#
#	###X Centering
#	if !centered:
#		###Up/Down Re-Centering
#		if centering_time_left == centering_time:
#			#Calculate x rotation angle before dividing it for centering
#			rotate_angle.x = (centering_angle.x - current_camera_angle.x)
#			#Looking down at greater than camera_angle_lim.x
#			if (rotate_angle.x > camera_angle_lim.x):
#				rotate_angle.x = rotate_angle.x - deg2rad(360)
#			##Looking up at greater than =-camera_angle_lim.x
#			if (rotate_angle.x < -camera_angle_lim.x):
#				rotate_angle.x = rotate_angle.x + deg2rad(360)
#
#			rotate_angle.x = rotate_angle.x/centering_time
#
#		###X Rotation
#		$Pivot.rotate_x(rotate_angle.x)
#	else:
#		#Just move to facing angle if center point reached
#		rotate_angle.x = (centering_angle.x - current_camera_angle.x)
#		$Pivot.rotate_x(rotate_angle.x)
#
#	###Decrement Timer
#	centering_time_left -= 1


func get_body_centering_angle(body_node):
	var facing_angle = body_node.get_global_transform().basis.get_euler().y
	
	if is_targetting:
		var target_position = focus_object.get_global_transform().origin
		var target_angle = calculate_global_y_rotation(owner.get_global_transform().origin.direction_to(target_position))
		
		###Body Y Rotation
		if !centered:
			if centering_time_left == centering_time:
				body_turn_angle.y = target_angle - facing_angle
				#Turning left at degrees > 180
				if (body_turn_angle.y > deg2rad(180)):
					body_turn_angle.y = body_turn_angle.y - deg2rad(360)
				#Turning right at degrees < -180
				if (body_turn_angle.y < deg2rad(-180)):
					body_turn_angle.y = body_turn_angle.y + deg2rad(360)
				body_turn_angle.y = body_turn_angle.y/centering_time_left
		else:
			body_turn_angle.y = target_angle - facing_angle
	else:
		body_turn_angle.y = 0
		
		
	return body_turn_angle


func get_camera_direction(camera, pivot):
	var camera_location = camera.get_global_transform().origin
	var focus_location = pivot.get_global_transform().origin
	
	var camera_direction = camera_location.direction_to(focus_location)
	
	return camera_direction


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


func reset_recenter():
	centered = false
	centering_time_left = centering_time


func get_node_direction(node):
	var direction = Vector3(0,0,1)
	var rotate_by = node.get_global_transform().basis.get_euler()
	direction = direction.rotated(Vector3(1,0,0), rotate_by.x)
	direction = direction.rotated(Vector3(0,1,0), rotate_by.y)
	direction = direction.rotated(Vector3(0,0,1), rotate_by.z)
	
	return direction


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


func _on_Nikkiv2_focus_target(target_pos_node):
	if target_pos_node:
		focus_object = target_pos_node
		is_targetting = true
		centering = true
	else:
		focus_object = target_pos_node
		is_targetting = false
		centering = false

