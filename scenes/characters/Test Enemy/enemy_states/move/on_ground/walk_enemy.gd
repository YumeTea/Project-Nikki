extends "res://scenes/characters/Test Enemy/enemy_states/move/on_ground/on_ground_enemy.gd"


#Animation Variables
#Idle
const idle_time_scale_default = 1.0
const idle_default_blend = 0
const idle_bow_blend = -0.8
#Walk
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
	speed = speed_default
	quick_turn = true #quick turn must be true at start
	is_falling = false
	centered = false
	centering_time_left = centering_time
	connect_enemy_signals()
	if owner.get_node("AnimationTree").get("parameters/StateMachineMove/playback").is_playing() == false:
		owner.get_node("AnimationTree").get("parameters/StateMachineMove/playback").start("Walk")
	else:
		owner.get_node("AnimationTree").get("parameters/StateMachineMove/playback").travel("Walk")
	
	.enter()


#Cleans up state, reinitializes values like timers
func exit():
	is_moving = false
	
	#Clear active tweens
	remove_active_tween("parameters/StateMachineMove/Walk/BlendSpace1D/1/blend_position")
	
	#Set walk anim blend back to idle
	owner.get_node("AnimationTree").set("parameters/StateMachineMove/Walk/BlendSpace1D/blend_position", 0.0)
	
	disconnect_enemy_signals()
	
	.exit()


#Creates output based on the input event passed in
func handle_input(event):
	.handle_input(event)


func handle_ai_input():
	.handle_ai_input()


#Acts as the _process method would
func update(delta):
	var facing_dot_velocity_horizontal = Vector2(facing_direction.x, facing_direction.z).dot(Vector2(velocity.x, velocity.z))
	
	#If stopped or moving backwards with no input, go to idle
	if (velocity == Vector3(0,0,0) or facing_dot_velocity_horizontal < 0.0) and left_joystick_axis == Vector2(0,0):
		is_moving = false
		is_falling = false
	
	#Determine player's speed
	if state_action == "None" and speed != speed_default:
		var walk_blend_position = owner.get_node("AnimationTree").get("parameters/StateMachineMove/Walk/BlendSpace1D/blend_position")
		#Wait for any blend value transitions to finish before setting speed
		if walk_blend_position < 0:
			pass
		else:
			speed = speed_default
		
	walk_first_person(delta)
	
	.update(delta)


func on_animation_started(_anim_name):
	return


func on_animation_finished(_anim_name):
	return


func walk_first_person(delta):
	direction = get_input_direction()
	facing_angle.y = owner.get_node("Rig").get_global_transform().basis.get_euler().y
	camera_angle_global.y = calculate_global_y_rotation(camera_direction)
	direction_angle.y = calculate_global_y_rotation(direction)
	
	###Check if next_turn_angle is within focus_angle_lim
	var next_turn_angle = Vector2()

	if direction.length() > 0.0:
		next_turn_angle.y = direction_angle.y - camera_angle_global.y
	else:
		next_turn_angle.y = 0.0
	
	#Turn angle bounding
	next_turn_angle.y = bound_angle(next_turn_angle.y)
	
	if !centering_view and !strafe_locked and ((next_turn_angle.y < focus_angle_lim.y - deg2rad(2.0)) and (next_turn_angle.y > -focus_angle_lim.y + deg2rad(2.0))):
		walk_free(delta)
	elif centering_view:
		walk_locked_first_person(delta)
	else:
		walk_strafe(delta) #if trying to turn to where neck is over focus angle lim, strafe walk instead
	
	blend_move_anim()


func walk_free(delta):
	direction = get_input_direction()
	facing_angle.y = Rig.get_global_transform().basis.get_euler().y
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


#Locks rig to target or focus angle (assumes locked camera control)
func walk_locked_first_person(delta):
	direction = get_input_direction()
	facing_angle.y = owner.get_node("Rig").get_global_transform().basis.get_euler().y
	
	direction_angle.y = calculate_global_y_rotation(direction)
	
	if centering_time_left <= 0:
		centered = true
		
	
	#Calculate turn angle based on target angle
	if focus_object != null:
		var target_position = focus_object.global_transform.origin
		var target_angle = calculate_global_y_rotation(Enemy.global_transform.origin.direction_to(target_position))
		
		turn_angle.y = target_angle - facing_angle.y
		turn_angle.y = bound_angle(turn_angle.y)
		if !centered:
			turn_angle.y = turn_angle.y/centering_time_left
	else:
		camera_angle_global.y = calculate_global_y_rotation(camera_direction)
		facing_angle.y = Rig.global_transform.basis.get_euler().y
		
		turn_angle.y = camera_angle_global.y - facing_angle.y
		turn_angle.y = bound_angle(turn_angle.y)
		if !centered:
			turn_angle.y = turn_angle.y/centering_time_left
		
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


###ANIMATION FUNCTIONS###


func blend_move_anim():
	var time_scale
	var tween_time = 0.25
	
	
	move_blend_position = owner.get_node("AnimationTree").get("parameters/StateMachineMove/Walk/BlendSpace1D/blend_position")
	
	###Blend position tweening
	#Going from Idle to Walk
	if direction.length() > 0.0 and !is_equal_approx(move_blend_position, 1.0) and !active_tweens.has("parameters/StateMachineMove/Walk/BlendSpace1D/blend_position"):
		var seconds = (1.0 - move_blend_position) * tween_time
		#Transition to Walk
		owner.get_node("Tween").interpolate_property(owner.get_node("AnimationTree"), "parameters/StateMachineMove/Walk/BlendSpace1D/blend_position", move_blend_position, 1.0, seconds, Tween.TRANS_LINEAR)
		owner.get_node("Tween").start()
		
		add_active_tween("parameters/StateMachineMove/Walk/BlendSpace1D/blend_position")
	#Going from Walk to Idle
	elif (direction.length() == 0.0 and acceleration_horizontal <= 0.0 and !is_equal_approx(move_blend_position, 0.0)):
		if active_tweens.has("parameters/StateMachineMove/Walk/BlendSpace1D/blend_position"):
			owner.get_node("Tween").stop(owner.get_node("AnimationTree"), "parameters/StateMachineMove/Walk/BlendSpace1D/blend_position")
		
		var seconds = (move_blend_position) * tween_time
		owner.get_node("Tween").interpolate_property(owner.get_node("AnimationTree"), "parameters/StateMachineMove/Walk/BlendSpace1D/blend_position", move_blend_position, 0.0, seconds, Tween.TRANS_LINEAR)
		owner.get_node("Tween").start()
		
		if !active_tweens.has("parameters/StateMachineMove/Walk/BlendSpace1D/blend_position"):
			add_active_tween("parameters/StateMachineMove/Walk/BlendSpace1D/blend_position")
	else:
		remove_active_tween("parameters/StateMachineMove/Walk/BlendSpace1D/blend_position")
	
	#Determine time scale blend function based on what anim is playing
	if move_blend_position > 0.0:
		blend_walk_anim()
	else:
		blend_idle_anim()


func blend_idle_anim():
	var idle_blend_position = owner.get_node("AnimationTree").get("parameters/StateMachineMove/Walk/BlendSpace1D/0/blend_position")
	
	#Bow Idle Blend
	if state_action == "Bow":
		if idle_blend_position != idle_bow_blend and !active_tweens.has("parameters/StateMachineMove/Walk/BlendSpace1D/0/blend_position"):
			owner.get_node("Tween").interpolate_property(owner.get_node("AnimationTree"), "parameters/StateMachineMove/Walk/BlendSpace1D/0/blend_position", idle_blend_position, idle_bow_blend, 0.25, Tween.TRANS_LINEAR)
			owner.get_node("Tween").start()
			add_active_tween("parameters/StateMachineMove/Walk/BlendSpace1D/0/blend_position")
		elif idle_blend_position == idle_bow_blend and active_tweens.has("parameters/StateMachineMove/Walk/BlendSpace1D/0/blend_position"):
			remove_active_tween("parameters/StateMachineMove/Walk/BlendSpace1D/0/blend_position")
	
	#None Idle Blend
	else:
		#Animate blend to default idle blend position if coming out of bow state
		if is_equal_approx(idle_blend_position, idle_bow_blend):
			owner.get_node("Tween").interpolate_property(owner.get_node("AnimationTree"), "parameters/StateMachineMove/Walk/BlendSpace1D/0/blend_position", idle_blend_position, 0.0, 0.25, Tween.TRANS_LINEAR)
			owner.get_node("Tween").start()
			add_active_tween("parameters/StateMachineMove/Walk/BlendSpace1D/0/blend_position")
		#Clear active tweens if not animating blend position between states
		elif idle_blend_position > idle_default_blend or is_equal_approx(idle_blend_position, idle_default_blend):
			remove_active_tween("parameters/StateMachineMove/Walk/BlendSpace1D/0/blend_position")
	
	owner.get_node("AnimationTree").set("parameters/StateMachineMove/Walk/TimeScale/scale", idle_time_scale_default)


func blend_walk_anim():
	var time_scale
	var walk_time_scale
	var run_time_scale
	var bow_walk_time_scale
	
	
	var walk_blend_position = owner.get_node("AnimationTree").get("parameters/StateMachineMove/Walk/BlendSpace1D/1/blend_position")
	
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
		
		#Set walk node blend position and time scale
		owner.get_node("AnimationTree").set("parameters/StateMachineMove/Walk/BlendSpace1D/1/blend_position", blend_position)
		owner.get_node("AnimationTree").set("parameters/StateMachineMove/Walk/TimeScale/scale", time_scale)





