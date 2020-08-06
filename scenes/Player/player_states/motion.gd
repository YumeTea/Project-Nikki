extends "res://scenes/Player/player_states/interaction/interaction.gd"


###Physics Variables
var position
var height
var direction = Vector3(0,0,0)
var direction_angle = 0
var velocity = Vector3(0,0,0)
const gravity = -9.8
const weight = 5

#Input Variables
var left_joystick_axis = Vector2(0,0)
var right_joystick_axis = Vector2(0,0)
var joystick_deadzone = 0.1
var joystick_sensitivity = 1.5 #####CONSIDER SETTING THIS A DIFFERENT, GLOBAL WAY

###Player Movement Variables
##Walk variables
const speed = 18
const turn_radius = 4 			#in degrees
const quick_turn_radius = 10 	#in degrees
const uturn_radius = 2 			#in degrees
#const MAX_RUNNING_SPEED = 9
const ACCEL = 6
const DEACCEL = 6

var snap_vector_default = Vector3(0,-1,0)
var snap_vector = snap_vector_default #Used for Move_and_slide_with_snap

#Centering Variables
var turn_angle

#Walking Flags
var is_walking = false
var quick_turn = true

#Creates output based on the input event passed in
func handle_input(event):
	if event is InputEventJoypadMotion and event.get_device() == 0:
		get_left_joystick_input(event)
		get_right_joystick_input(event)
	if Input.is_action_pressed("center_view"):
		movement_locked = true
		if event.is_action_pressed("center_view") and event.get_device() == 0:
			reset_recenter()
	else: #checks all input to see if pressed, not just event
		movement_locked = false
		centered = false
	.handle_input(event)


#Acts as the _process method would
func update(delta):
	###Gravity
	velocity.y += weight * gravity * delta
	velocity = owner.move_and_slide_with_snap(velocity, snap_vector, Vector3(0,1,0), true, 1, deg2rad(65), false) #Come back/check vars 3,4,5
	position = owner.get_global_transform().origin
	height = position.y
	emit_signal("position_changed", position)
	emit_signal("velocity_changed", velocity)
	.update(delta)


func _on_animation_finished(anim_name):
	return


func get_input_direction():
	direction = Vector3() #Resets direction of player to default
	
	###Camera Direction
	var aim = camera.get_global_transform().basis.get_euler()
	
	###Directional Input
	direction.z -= left_joystick_axis.y
	direction.x -= left_joystick_axis.x
	
	direction = direction.rotated(Vector3(0,1,0), (aim.y + PI))
	
	
	direction.y = 0
	direction = direction.normalized()
	return direction


func get_left_joystick_input(event):
	if event is InputEventJoypadMotion and event.get_device() == 0:
		if event.get_axis() == 0:
			if event.get_axis_value() < joystick_deadzone and event.get_axis_value() > -joystick_deadzone:
				left_joystick_axis.x = 0
			else:
				left_joystick_axis.x = event.get_axis_value() * joystick_sensitivity
		if event.get_axis() == 1:
			if event.get_axis_value() < joystick_deadzone and event.get_axis_value() > -joystick_deadzone:
				left_joystick_axis.y = 0
			else:
				left_joystick_axis.y = event.get_axis_value() * joystick_sensitivity


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


func walk_free(delta):
	direction = get_input_direction()
	facing_angle = owner.get_node("Rig").get_global_transform().basis.get_euler().y

	direction_angle = calculate_global_y_rotation(direction)

	var turn_angle
	
	turn_angle = direction_angle - facing_angle
	###Turn angle bounding
	#Turning left at degrees > 180
	if (turn_angle > deg2rad(180)):
		turn_angle = turn_angle - deg2rad(360)
	#Turning right at degrees < -180
	if (turn_angle < deg2rad(-180)):
		turn_angle = turn_angle + deg2rad(360)
	
	###Turn radius limiting
	if is_walking:
		#Turn radius control left
		if turn_angle < (-deg2rad(turn_radius)):
			turn_angle = (-deg2rad(turn_radius))
		#Turn radius control right
		if turn_angle > (deg2rad(turn_radius)):
			turn_angle = (deg2rad(turn_radius))
		#Change input direction to match facing direction
		if (direction.x != 0 or direction.z != 0):
			direction_angle = facing_angle + turn_angle
			direction.z = cos(direction_angle)
			direction.x = sin(direction_angle)
	
	###Quick turn radius limiting
	if quick_turn:
		#Quick turn radius control left
		if turn_angle < (-deg2rad(quick_turn_radius)):
			turn_angle = (-deg2rad(quick_turn_radius))
		#Quick turn radius control right
		if turn_angle > (deg2rad(quick_turn_radius)):
			turn_angle = (deg2rad(quick_turn_radius))
		if direction_angle == facing_angle + turn_angle:
			is_walking = true
			quick_turn = false
	
	calculate_movement_velocity(delta)
	
	###Player Rotation
	if direction:
		owner.get_node("Rig").rotate_y(turn_angle)
	else:
		is_walking = false
		quick_turn = true


#func walk_free(delta):
#	direction = get_input_direction() #Also sets facing angle
#
#	direction_angle = calculate_global_y_rotation(direction)
#
#	var turn_angle = direction_angle - facing_angle
#
#	###Turn radius limiting
#	if is_walking == true:
#		#Turning left at degrees > 180
#		if (turn_angle > deg2rad(180)):
#			turn_angle = turn_angle - deg2rad(360)
#		#Turning right at degrees < -180
#		if (turn_angle < deg2rad(-180)):
#			turn_angle = turn_angle + deg2rad(360)
#		#Turn radius control left
#		if (turn_angle < (-deg2rad(turn_radius)) and turn_angle > deg2rad(-180 + uturn_radius)):
#			turn_angle = (-deg2rad(turn_radius))
#		elif turn_angle < deg2rad(-180 + uturn_radius): #for near 180 turn
#			turn_angle = -deg2rad(quick_turn_radius)
#		#Turn radius control right
#		if (turn_angle > (deg2rad(turn_radius)) and turn_angle < deg2rad(180 - uturn_radius)):
#			turn_angle = (deg2rad(turn_radius))
#		elif turn_angle > deg2rad(180 - uturn_radius): #for near 180 turn
#			turn_angle = deg2rad(quick_turn_radius)
#		#Change input direction to match facing direction
#		if (direction.x != 0 or direction.z != 0):
#			direction_angle = facing_angle + turn_angle
#			direction.z = cos(direction_angle)
#			direction.x = sin(direction_angle)
#
#	calculate_movement_velocity(delta)
#
#	###Player Rotation
#	if direction:
#		owner.get_node("Rig").rotate_y(direction_angle - facing_angle)
#		is_walking = true #is_walking set true after first pass to allow instant turn from stop
#	else:
#		is_walking = false


func walk_locked(delta):
	direction = get_input_direction()
	facing_angle = owner.get_node("Rig").get_global_transform().basis.get_euler().y
	
	direction_angle = calculate_global_y_rotation(direction) #angle between current direction and input direction
	
	calculate_movement_velocity(delta)
	
	if centering_time_left <= 0:
		centered = true
		
		
	if focus_target_pos != null:
		var target_position = focus_target_pos.get_global_transform().origin
		var target_angle = calculate_global_y_rotation(owner.get_global_transform().origin.direction_to(target_position))
		
		if !centered:
			turn_angle = target_angle - facing_angle
			#Turning left at degrees > 180
			if (turn_angle > deg2rad(180)):
				turn_angle = turn_angle - deg2rad(360)
			#Turning right at degrees < -180
			if (turn_angle < deg2rad(-180)):
				turn_angle = turn_angle + deg2rad(360)
			turn_angle = turn_angle/centering_time_left
		else:
			turn_angle = target_angle - facing_angle
	else:
		turn_angle = 0
		
	emit_signal("center_view", turn_angle)
	
	###Player Rotation
	owner.get_node("Rig").rotate_y(turn_angle)
	
	if direction:
		is_walking = true
	else:
		is_walking = false
		
		
	###Decrement Timer
	if centering_time_left > 0:
		centering_time_left -= 1


func calculate_movement_velocity(delta):
	###Velocity Calculation
	var temp_velocity = velocity
	temp_velocity.y = 0

	###Acceleration Calculation
	var target = direction * speed

	var acceleration
	if direction.dot(temp_velocity) > 0:
		acceleration = ACCEL
	else:
		acceleration = DEACCEL

	#Calculate a portion of the distance to go
	temp_velocity = temp_velocity.linear_interpolate(target, acceleration * delta)

	###Final Velocity
	if (abs(temp_velocity.x) > 0.1):
		velocity.x = temp_velocity.x
	else:
		velocity.x = 0
	if (abs(temp_velocity.z) > 0.1):
		velocity.z = temp_velocity.z
	else:
		velocity.z = 0


func reset_recenter():
	centered = false
	centering_time_left = centering_time


func calculate_global_y_rotation(direction):
	var test_direction = Vector2(0,1)
	var direction_to = Vector2(direction.x, direction.z)
	var y_rotation = -test_direction.angle_to(direction_to)
	return y_rotation #Output is PI > y > -PI

