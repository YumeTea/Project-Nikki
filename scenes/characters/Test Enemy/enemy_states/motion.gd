extends "res://scenes/characters/Test Enemy/enemy_states/interaction/interaction.gd"


###Physics Variables
var position
var height
var direction = Vector3(0,0,0)
var direction_angle = 0
var velocity = Vector3(0,0,0)
const gravity = -9.8
const weight = 5

#Input Variables
var move_direction = Vector2(0,0)
var look_direction = Vector2(0,0)
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


#Creates output based on the input event passed in
func handle_input(event):
	.handle_input(event)


func handle_ai_input(input):
	get_move_direction(move_direction)
	get_look_direction(look_direction)
	if is_ai_action_pressed("center_view", input):
		movement_locked = true
	else:
		movement_locked = false
	.handle_ai_input(input)


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


func get_movement_direction():
	direction = Vector3() #Resets direction of enemy to default
	
	###Head Direction
	var aim = head.get_global_transform().basis.get_euler()
	facing_angle = owner.get_node("Rig").get_global_transform().basis.get_euler().y
	
	###Directional Input
	direction.z -= move_direction.y
	direction.x -= move_direction.x
	
	direction = direction.rotated(Vector3(0,1,0), (aim.y + PI))
	
	
	direction.y = 0
	direction = direction.normalized()
	return direction


func get_move_direction(direction):
	input["left_stick"] = direction
	
	return move_direction


func get_look_direction(direction):
	input["right_stick"] = direction
	
	return look_direction


func walk_free(delta):
	direction = get_movement_direction() #Also sets facing angle
	
	direction_angle = calculate_global_y_rotation(direction)
	
	var turn_angle = direction_angle - facing_angle
	
	###Turn radius limiting
	if is_walking == true:
		#Turning left at degrees > 180
		if (turn_angle > deg2rad(180)):
			turn_angle = turn_angle - deg2rad(360)
		#Turning right at degrees < -180
		if (turn_angle < deg2rad(-180)):
			turn_angle = turn_angle + deg2rad(360)
		#Turn radius control left
		if (turn_angle < (-deg2rad(turn_radius)) and turn_angle > deg2rad(-180 + uturn_radius)):
			turn_angle = (-deg2rad(turn_radius))
		elif turn_angle < deg2rad(-180 + uturn_radius): #for near 180 turn
			turn_angle = -deg2rad(quick_turn_radius)
		#Turn radius control right
		if (turn_angle > (deg2rad(turn_radius)) and turn_angle < deg2rad(180 - uturn_radius)):
			turn_angle = (deg2rad(turn_radius))
		elif turn_angle > deg2rad(180 - uturn_radius): #for near 180 turn
			turn_angle = deg2rad(quick_turn_radius)
		#Change input direction to match facing direction
		if (direction.x != 0 or direction.z != 0):
			direction_angle = facing_angle + turn_angle
			direction.z = cos(direction_angle)
			direction.x = sin(direction_angle)
	
	calculate_movement_velocity(delta)
	
	###Player Rotation
	if direction:
		owner.get_node("Rig").rotate_y(direction_angle - facing_angle)
		#Send signal for facing direction change
		emit_signal("facing_direction_changed", get_node_direction(owner.get_node("Rig")))
		is_walking = true #is_walking set true after first pass to allow instant turn from stop
	else:
		is_walking = false


func walk_locked(delta):
	direction = get_movement_direction()
	
	direction_angle = calculate_global_y_rotation(direction) #angle between current direction and input direction
	
	calculate_movement_velocity(delta)
	
	if focus_target_pos != null:
		var target_position = focus_target_pos.get_global_transform().origin
		var target_angle = calculate_global_y_rotation(owner.get_global_transform().origin.direction_to(target_position))
		
		#Checks if centered based on camera rig signal
		if centering_time_left <= 0:
			centered = true
		
		if !centered:
			turn_angle = target_angle - facing_angle
			#Turning left at degrees > 180
			if (turn_angle > deg2rad(180)):
				turn_angle = turn_angle - deg2rad(360)
			#Turning right at degrees < -180
			if (turn_angle < deg2rad(-180)):
				turn_angle = turn_angle + deg2rad(360)
			turn_angle = turn_angle/centering_time_left
			direction_angle = facing_angle + turn_angle
		else:
			direction_angle = target_angle
	else:
		direction_angle = facing_angle
	
	###Enemy Rotation
	owner.get_node("Rig").rotate_y(direction_angle - facing_angle)
	
	#Send signal for facing direction change
	emit_signal("facing_direction_changed", get_node_direction(owner.get_node("Rig")))
	
	if direction:
		is_walking = true
	else:
		is_walking = false

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


func calculate_global_y_rotation(direction):
	var test_direction = Vector2(0,1)
	var direction_to = Vector2(direction.x, direction.z)
	var y_rotation = -test_direction.angle_to(direction_to)
	return y_rotation #Output is PI > y > -PI


func get_node_direction(node):
	var direction = Vector3(0,0,1)
	var rotate_by = node.get_global_transform().basis.get_euler()
	direction = direction.rotated(Vector3(1,0,0), rotate_by.x)
	direction = direction.rotated(Vector3(0,1,0), rotate_by.y)
	direction = direction.rotated(Vector3(0,0,1), rotate_by.z)
	
	return direction

