extends "res://scenes/Player/player_states/move/on_ground/on_ground.gd"


#Animation Variables
const walk_anim_speed_max = 1.3
const run_anim_speed_max = 2.2
const bow_walk_anim_speed_max = 1.55
const blend_lower_lim = 5.0
const blend_upper_lim = 15.0


func initialize(init_values_dic):
	for value in init_values_dic:
		self[value] = init_values_dic[value]


#Initializes state, changes animation, etc
func enter():
	quick_turn = true #quick turn must be true at start
	is_falling = false
	centered = false
	centering_time_left = centering_time
	connect_player_signals()
	if owner.get_node("AnimationTree").get("parameters/StateMachineMove/playback").is_playing() == false:
		owner.get_node("AnimationTree").get("parameters/StateMachineMove/playback").start("Walk")
	else:
		owner.get_node("AnimationTree").get("parameters/StateMachineMove/playback").travel("Walk")
	
	.enter()

#Cleans up state, reinitializes values like timers
func exit():
	is_moving = false
	
	#Clear active tweens
	remove_active_tween("parameters/StateMachineMove/Walk/BlendSpace1D/blend_position")
	
	disconnect_player_signals()
	
	.exit()


#Creates output based on the input event passed in
func handle_input(event):
	.handle_input(event)


#Acts as the _process method would
func update(delta):
	var facing_dot_velocity_horizontal = Vector2(facing_direction.x, facing_direction.z).dot(Vector2(velocity.x, velocity.z))
	
	#If stopped or moving backwards with no input, go to idle
	if (velocity == Vector3(0,0,0) or facing_dot_velocity_horizontal < 0.0) and left_joystick_axis == Vector2(0,0):
		emit_signal("finished", "idle")
	
	#Determine player's speed
	if state_action == "None" and speed != speed_default:
		var walk_blend_position = owner.get_node("AnimationTree").get("parameters/StateMachineMove/Walk/BlendSpace1D/blend_position")
		#Wait for any blend value transitions to finish before setting speed
		if walk_blend_position < 0:
			pass
		else:
			speed = speed_default
	
	if view_mode == "third_person":
		walk_third_person(delta)
	if view_mode == "first_person":
		walk_first_person(delta)
	
	.update(delta)


func on_animation_finished(_anim_name):
	return


func walk_third_person(delta):
	if !centering_view and !strafe_locked:
		walk_free(delta)
	elif centering_view:
		walk_locked_third_person(delta)
	elif strafe_locked:
		walk_strafe(delta)
	
	blend_move_anim()


func walk_first_person(delta):
	direction = get_input_direction()
	facing_angle.y = owner.get_node("Rig").get_global_transform().basis.get_euler().y
	camera_angle_global.y = calculate_global_y_rotation(camera_direction)
	direction_angle.y = calculate_global_y_rotation(direction)
	
	var next_turn_angle = Vector2()
	next_turn_angle.y = direction_angle.y - camera_angle_global.y
	
	###Turn angle bounding
	next_turn_angle.y = bound_angle(next_turn_angle.y)
	
	if rotate_to_focus:
		walk_rotate_to_focus(delta) #for entering first person
	elif !centering_view and !strafe_locked and ((next_turn_angle.y < focus_angle_lim.y - deg2rad(2.0)) and (next_turn_angle.y > -focus_angle_lim.y + deg2rad(2.0))):
		walk_free(delta)
	elif centering_view:
		walk_locked_first_person(delta)
	else:
		walk_strafe(delta) #if trying to turn to where neck is over focus angle lim, strafe walk instead
	
	blend_move_anim()


func walk_free(delta):
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
		direction_angle.y = facing_angle.y + turn_angle.y
		direction = direction.rotated(Vector3(0,1,0), -(input_direction_angle - direction_angle.y))
		velocity = velocity.rotated(Vector3(0,1,0), turn_angle.y)
	
	
	
	###Quick turn radius limiting
	if quick_turn:
		#Quick turn radius control left
		if turn_angle.y < (-deg2rad(quick_turn_radius)):
			turn_angle.y = (-deg2rad(quick_turn_radius))
		#Quick turn radius control right
		elif turn_angle.y > (deg2rad(quick_turn_radius)):
			turn_angle.y = (deg2rad(quick_turn_radius))
		#Stop quick turning once facing angle matches input direction angle
		if is_equal_approx(turn_angle.y, 0.0):
			is_moving = true
			quick_turn = false
	
	calculate_movement_velocity(delta)
	
	###Player Rotation
	if direction:
		Rig.rotate_y(turn_angle.y)


#Locks rig to target or rig facing angle (assumes locked camera control)
func walk_locked_third_person(delta):
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
		turn_angle.y = 0
		
	emit_signal("center_view", turn_angle.y)
	
	calculate_movement_velocity(delta)
	
	###Player Rotation
	Rig.rotate_y(turn_angle.y)
	
	if direction:
		is_moving = true
	else:
		is_moving = false
		
	###Decrement Timer
	if centering_time_left > 0:
		centering_time_left -= 1


#Locks rig to target or focus angle (assumes locked camera control)
func walk_locked_first_person(delta):
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
	
	calculate_movement_velocity(delta)
	
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
func walk_strafe(delta):
	direction = get_input_direction()
	facing_angle.y = owner.get_node("Rig").get_global_transform().basis.get_euler().y
	camera_angle_global.y = calculate_global_y_rotation(camera_direction)
	
	direction_angle.y = calculate_global_y_rotation(direction)
	
	calculate_movement_velocity(delta)
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
func walk_rotate_to_focus(delta):
	direction = get_input_direction()
	facing_angle.y = owner.get_node("Rig").get_global_transform().basis.get_euler().y
	camera_angle_global.y = calculate_global_y_rotation(camera_direction)
	
	direction_angle.y = calculate_global_y_rotation(direction)
	
	calculate_movement_velocity(delta)
	
	turn_angle.y = camera_angle_global.y - facing_angle.y
	turn_angle.y = bound_angle(turn_angle.y)
	if view_change_time_left > 0:
		turn_angle.y = turn_angle.y/view_change_time_left
	
	
	###Player Rotation
	owner.get_node("Rig").rotate_y(turn_angle.y)
	
	#Decrement Timer
	if view_change_time_left > 0:
		view_change_time_left -= 1
		
	if view_change_time_left <= 0:
		centered = true
		rotate_to_focus = false


func blend_move_anim():
	var time_scale
	var bow_walk_time_scale
	
	###Walk/Run Blending
	#Set move blend position in case coming from idle
#	owner.get_node("AnimationTree").set("parameters/StateMachineMove/Walk/BlendSpace1D/blend_position", move_blend_position)
	
	move_blend_position = owner.get_node("AnimationTree").get("parameters/StateMachineMove/Walk/BlendSpace1D/blend_position")
	
	#Bow Walk Blend
	if state_action == "Bow":
		#Check move position and if move position is already being tweened
		if move_blend_position != -1.0 and !active_tweens.has("parameters/StateMachineMove/Walk/BlendSpace1D/blend_position"):
			#Transition to bow walk
			owner.get_node("Tween").interpolate_property(owner.get_node("AnimationTree"), "parameters/StateMachineMove/Walk/BlendSpace1D/blend_position", move_blend_position, -1.0, 0.25, Tween.TRANS_LINEAR)
			owner.get_node("Tween").start()
			add_active_tween("parameters/StateMachineMove/Walk/BlendSpace1D/blend_position")
		elif move_blend_position == -1.0 and active_tweens.has("parameters/StateMachineMove/Walk/BlendSpace1D/blend_position"):
			remove_active_tween("parameters/StateMachineMove/Walk/BlendSpace1D/blend_position")
	
	#None Walk Blend
	else:
		if move_blend_position < 0 and !active_tweens.has("parameters/StateMachineMove/Walk/BlendSpace1D/blend_position"):
			#Transition to walk
			owner.get_node("Tween").interpolate_property(owner.get_node("AnimationTree"), "parameters/StateMachineMove/Walk/BlendSpace1D/blend_position", move_blend_position, 0.0, 0.25, Tween.TRANS_LINEAR)
			owner.get_node("Tween").start()
			add_active_tween("parameters/StateMachineMove/Walk/BlendSpace1D/blend_position")
		elif move_blend_position >= 0.0:
			if active_tweens.has("parameters/StateMachineMove/Walk/BlendSpace1D/blend_position"):
				remove_active_tween("parameters/StateMachineMove/Walk/BlendSpace1D/blend_position")
			
	#Run normal walk blending if no special walking
	blend_walk_anim(move_blend_position)


func blend_walk_anim(walk_blend_position):
	var time_scale
	var walk_time_scale
	var run_time_scale
	var bow_walk_time_scale
	
	
	if walk_blend_position < 0.0:
		bow_walk_time_scale = (velocity_horizontal / blend_lower_lim) * bow_walk_anim_speed_max
		
		time_scale = bow_walk_time_scale
		
		owner.get_node("AnimationTree").set("parameters/StateMachineMove/Walk/TimeScale/scale", bow_walk_time_scale)
	else:
		var blend_position
		
		if velocity_horizontal < blend_lower_lim:
			blend_position = 0.0
			
			walk_time_scale = (velocity_horizontal / blend_lower_lim) * walk_anim_speed_max
			
			time_scale = walk_time_scale
		elif velocity_horizontal < blend_upper_lim:
			blend_position = (velocity_horizontal - blend_lower_lim) / (blend_upper_lim - blend_lower_lim)
			
			walk_time_scale = (velocity_horizontal / blend_lower_lim) * walk_anim_speed_max
			run_time_scale = (velocity_horizontal / speed_default) * run_anim_speed_max
			
			time_scale = (walk_time_scale - (walk_time_scale * blend_position)) + (run_time_scale * blend_position)
		else:
			blend_position = 1.0
			
			run_time_scale = (velocity_horizontal / speed_default) * run_anim_speed_max
			
			time_scale = run_time_scale
		
		owner.get_node("AnimationTree").set("parameters/StateMachineMove/Walk/BlendSpace1D/blend_position", blend_position)
		owner.get_node("AnimationTree").set("parameters/StateMachineMove/Walk/TimeScale/scale", time_scale)





