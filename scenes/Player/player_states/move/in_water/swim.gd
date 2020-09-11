extends "res://scenes/Player/player_states/move/in_water/in_water.gd"


func initialize(init_values_dic):
	for value in init_values_dic:
		self[value] = init_values_dic[value]


#Initializes state, changes animation, etc
func enter():
	surfaced_height = surface_height - (player_center / 1.2)
	snap_vector = Vector3(0,0,0)
	
	connect_player_signals()
	
#	if owner.get_node("AnimationTree").get("parameters/StateMachineLowerBody/playback").is_playing() == false:
#		owner.get_node("AnimationTree").get("parameters/StateMachineLowerBody/playback").start("Swim")
#	else:
#		owner.get_node("AnimationTree").get("parameters/StateMachineLowerBody/playback").travel("Swim")


#Cleans up state, reinitializes values like timers
func exit():
	#Clear active tweens
	
	disconnect_player_signals()


#Creates output based on the input event passed in
func handle_input(event):
	.handle_input(event)


#Acts as the _process method would
func update(delta):
	if Player.global_transform.origin.y >= surfaced_height + (surface_speed * 1.01 * delta):
		emit_signal("finished", "previous")
	
	if view_mode == "third_person":
		swim_third_person(delta)
	if view_mode == "first_person":
		swim_first_person(delta)
		
	calculate_swim_velocity(delta)
	
	.update(delta)


func on_animation_finished(_anim_name):
	pass


func swim_third_person(delta):
	if !centering_view and !strafe_locked:
		swim_free(delta)
	elif centering_view:
		swim_locked_third_person(delta)
	elif strafe_locked:
		swim_strafe(delta)
	
#	blend_move_anim()


func swim_first_person(delta):
	direction = get_input_direction()
	facing_angle.y = owner.get_node("Rig").get_global_transform().basis.get_euler().y
	camera_angle_global.y = calculate_global_y_rotation(camera_direction)
	direction_angle.y = calculate_global_y_rotation(direction)
	
	var next_turn_angle = Vector2()
	next_turn_angle.y = direction_angle.y - camera_angle_global.y
	
	###Turn angle bounding
	next_turn_angle.y = bound_angle(next_turn_angle.y)
	
	if rotate_to_focus:
		swim_rotate_to_focus(delta) #for entering first person
	elif !centering_view and !strafe_locked and ((next_turn_angle.y < focus_angle_lim.y) and (next_turn_angle.y > -focus_angle_lim.y)):
		swim_free(delta)
	elif centering_view:
		swim_locked_first_person(delta)
	else:
		swim_strafe(delta) #if trying to turn to where neck is over focus angle lim, strafe swim instead
	
#	blend_move_anim()


func swim_free(delta):
	direction = get_input_direction()
	facing_angle.y = owner.get_node("Rig").get_global_transform().basis.get_euler().y
	var input_direction_angle = calculate_global_y_rotation(direction)
	
	if !direction:
		is_moving = false
		quick_turn = true
	
	###Turn angle calculations
	turn_angle.y = input_direction_angle - facing_angle.y
	###Turn angle bounding
	turn_angle.y = bound_angle(turn_angle.y)
	
	###Turn radius limiting
	if is_moving:
		#Turn radius control left
		if turn_angle.y < (-deg2rad(turn_radius)):
			turn_angle.y = (-deg2rad(turn_radius))
		#Turn radius control right
		elif turn_angle.y > (deg2rad(turn_radius)):
			turn_angle.y = (deg2rad(turn_radius))
		#Change direction and velocity to match new facing direction
		if (direction.x != 0 or direction.z != 0):
			direction_angle.y = facing_angle.y + turn_angle.y
			direction = direction.rotated(Vector3(0,1,0), direction_angle.y - input_direction_angle)
			velocity = velocity.rotated(Vector3(0,1,0), turn_angle.y)
	
	###Quick turn radius limiting
	if quick_turn:
		#Quick turn radius control left
		if turn_angle.y < (-deg2rad(quick_turn_radius)):
			turn_angle.y = (-deg2rad(quick_turn_radius))
		#Quick turn radius control right
		elif turn_angle.y > (deg2rad(quick_turn_radius)):
			turn_angle.y = (deg2rad(quick_turn_radius))
		if turn_angle.y == 0:
			is_moving = true
			quick_turn = false
	
	calculate_swim_velocity(delta)
	
	###Player Rotation
	if direction:
		owner.get_node("Rig").rotate_y(turn_angle.y)


#Locks rig to target or rig facing angle (assumes locked camera control)
func swim_locked_third_person(delta):
	direction = get_input_direction()
	facing_angle.y = owner.get_node("Rig").get_global_transform().basis.get_euler().y
	camera_angle_global.y = calculate_global_y_rotation(camera_direction)
	
	direction_angle.y = calculate_global_y_rotation(direction)
	
	if centering_time_left <= 0:
		centered = true
		
	
	#Calculate turn angle based on target angle
	if focus_object != null:
		var target_position = focus_object.get_global_transform().origin
		var target_angle = calculate_global_y_rotation(Player.get_global_transform().origin.direction_to(target_position))
		
		turn_angle.y = target_angle - facing_angle.y
		turn_angle.y = bound_angle(turn_angle.y)
		if !centered:
			turn_angle.y = turn_angle.y/centering_time_left
	else:
		turn_angle.y = camera_angle_global.y - facing_angle.y
		turn_angle.y = bound_angle(turn_angle.y)
		if !centered:
			turn_angle.y = turn_angle.y/centering_time_left
		
	emit_signal("center_view", turn_angle.y)
	
	calculate_swim_velocity(delta)
	
	###Player Rotation
	owner.get_node("Rig").rotate_y(turn_angle.y)
	
	if direction:
		is_moving = true
	else:
		is_moving = false
		
		
	###Decrement Timer
	if centering_time_left > 0:
		centering_time_left -= 1


#Locks rig to target or focus angle (assumes locked camera control)
func swim_locked_first_person(delta):
	direction = get_input_direction()
	facing_angle.y = owner.get_node("Rig").get_global_transform().basis.get_euler().y
	
	direction_angle.y = calculate_global_y_rotation(direction)
	
	if centering_time_left <= 0:
		centered = true
		
	
	#Calculate turn angle based on target angle
	if focus_object != null:
		var target_position = focus_object.get_global_transform().origin
		var target_angle = calculate_global_y_rotation(Player.get_global_transform().origin.direction_to(target_position))
		
		turn_angle.y = target_angle - facing_angle.y
		turn_angle.y = bound_angle(turn_angle.y)
		if !centered:
			turn_angle.y = turn_angle.y/centering_time_left
	else:
		camera_angle_global.y = calculate_global_y_rotation(camera_direction)
		facing_angle.y = owner.get_node("Rig").get_global_transform().basis.get_euler().y
		
		turn_angle.y = camera_angle_global.y - facing_angle.y
		turn_angle.y = bound_angle(turn_angle.y)
		if !centered:
			turn_angle.y = turn_angle.y/centering_time_left
		
	emit_signal("center_view", turn_angle.y)
	
	calculate_swim_velocity(delta)
	
	###Player Rotation
	owner.get_node("Rig").rotate_y(turn_angle.y)
	
	if direction:
		is_moving = true
	else:
		is_moving = false
		
		
	###Decrement Timer
	if centering_time_left > 0:
		centering_time_left -= 1


#Locks rig to focus angle
func swim_strafe(delta):
	direction = get_input_direction()
	facing_angle.y = owner.get_node("Rig").get_global_transform().basis.get_euler().y
	camera_angle_global.y = calculate_global_y_rotation(camera_direction)
	
	direction_angle.y = calculate_global_y_rotation(direction)
	
	calculate_swim_velocity(delta)
	if !direction:
		quick_turn = true
	
	###Turn angle calculations
	turn_angle.y = camera_angle_global.y - facing_angle.y
	###Turn angle bounding
	turn_angle.y = bound_angle(turn_angle.y)
	
	###Turn radius limiting
	#Turn radius control left
	if turn_angle.y < (-deg2rad(turn_radius)):
		turn_angle.y = (-deg2rad(turn_radius))
	#Turn radius control right
	if turn_angle.y > (deg2rad(turn_radius)):
		turn_angle.y = (deg2rad(turn_radius))


	###Player Rotation
	owner.get_node("Rig").rotate_y(turn_angle.y)

#Used to enter third person while moving
func swim_rotate_to_focus(delta):
	direction = get_input_direction()
	facing_angle.y = owner.get_node("Rig").get_global_transform().basis.get_euler().y
	camera_angle_global.y = calculate_global_y_rotation(camera_direction)
	
	direction_angle.y = calculate_global_y_rotation(direction)
	
	calculate_swim_velocity(delta)
	
	turn_angle.y = camera_angle_global.y - facing_angle.y
	turn_angle.y = bound_angle(turn_angle.y)
	turn_angle.y = turn_angle.y/centering_time_left
	
	
	###Player Rotation
	owner.get_node("Rig").rotate_y(turn_angle.y)
	
	#Decrement Timer
	if centering_time_left > 0:
		centering_time_left -= 1
		
	if centering_time_left <= 0:
		centered = true
		rotate_to_focus = false
		emit_signal("entered_new_view", view_mode)


