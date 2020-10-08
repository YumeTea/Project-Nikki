extends "res://scenes/Player/player_states/move/in_water/in_water.gd"

"""
Direction_angle may be unused
"""

#Animation Variables
var swim_anim_speed_max = 1.5
const blend_lower_lim = 5.0 #Velocity where idle changes to all dive_forward


func initialize(init_values_dic):
	for value in init_values_dic:
		self[value] = init_values_dic[value]


#Initializes state, changes animation, etc
func enter():
	velocity.y = -1.0
	speed = speed_swim
	quick_turn = true
	snap_vector = Vector3(0,0,0)
	
	connect_player_signals()
	
	if owner.get_node("AnimationTree").get("parameters/StateMachineMove/playback").is_playing() == false:
		owner.get_node("AnimationTree").get("parameters/StateMachineMove/playback").start("Swim")
	else:
		owner.get_node("AnimationTree").get("parameters/StateMachineMove/playback").travel("Swim")
	
	.enter()


#Cleans up state, reinitializes values like timers
func exit():
	#Rotate rig x rotation back to center
	var angle = calculate_local_x_rotation(facing_direction)
	angle = bound_angle(angle)
	rig_rotate_x_local(angle)
	
	#Clear active tweens
	remove_active_tween("parameters/StateMachineMove/Walk/BlendSpace1D/blend_position")
	
	disconnect_player_signals()
	
	.exit()


#Creates output based on the input event passed in
func handle_input(event):
	.handle_input(event)


#Acts as the _process method would
func update(delta):
	if Player.global_transform.origin.y >= surfaced_height + (surface_speed * 1.01 * delta):
		emit_signal("finished", "previous")
	
	if view_mode == "third_person":
		dive_third_person(delta)
	if view_mode == "first_person":
		dive_first_person(delta)
		
	calculate_dive_velocity(delta)
	
	.update(delta)
	
	if height >= surfaced_height:
		emit_signal("finished", "swim")


func on_animation_started(_anim_name):
	return


func on_animation_finished(_anim_name):
	pass


func dive_third_person(delta):
	if centering_view:
		dive_locked_third_person(delta)
	elif strafe_locked:
		dive_strafe(delta)
	
	blend_move_anim()


func dive_first_person(delta):
	if rotate_to_focus:
		dive_rotate_to_focus(delta) #for entering first person
	elif centering_view:
		dive_locked_first_person(delta)
	elif strafe_locked:
		dive_strafe(delta) #if trying to turn to where neck is over focus angle lim, strafe dive instead
	
	blend_move_anim()


#Locks rig to target or rig facing angle (assumes locked camera control)
func dive_locked_third_person(delta):
	direction = get_input_direction()
	facing_angle.x = -calculate_local_x_rotation(facing_direction)
	facing_angle.y = calculate_global_y_rotation(facing_direction)
	camera_angle_global.x = -calculate_local_x_rotation(camera_direction)
	camera_angle_global.y = calculate_global_y_rotation(camera_direction)
	
	direction_angle.y = calculate_global_y_rotation(direction)
	
	if centering_time_left <= 0:
		centered = true
		
	#Calculate turn angle based on target angle
	if focus_object != null:
		var target_angle : Vector2
		var target_position = focus_object.get_global_transform().origin
		target_angle.x = -calculate_local_x_rotation(Player.get_global_transform().origin.direction_to(target_position))
		target_angle.y = calculate_global_y_rotation(Player.get_global_transform().origin.direction_to(target_position))
		
		turn_angle = target_angle - facing_angle
		turn_angle.x = bound_angle(turn_angle.x)
		turn_angle.y = bound_angle(turn_angle.y)
		if !centered:
			turn_angle = turn_angle/centering_time_left
	else:
		#X
		turn_angle.x = -facing_angle.x
		if !centered:
			turn_angle.x = turn_angle.x/centering_time_left
		#Y
		turn_angle.y = 0.0
	
	
	calculate_dive_velocity(delta)
	
	
	###Player Rotation
	#X Rotation
	rig_rotate_x_local(turn_angle.x)
	
	#Y Rotation
	Rig.transform = Rig.transform.rotated(Vector3.UP, turn_angle.y)
	
	
	###Decrement Timer
	if centering_time_left > 0:
		centering_time_left -= 1


#Locks rig to target or focus angle (assumes locked camera control)
func dive_locked_first_person(delta):
	direction = get_input_direction()
	facing_angle.x = -calculate_local_x_rotation(facing_direction)
	facing_angle.y = calculate_global_y_rotation(facing_direction)
	camera_angle_global.x = -calculate_local_x_rotation(camera_direction)
	camera_angle_global.y = calculate_global_y_rotation(camera_direction)
	
	direction_angle.y = calculate_global_y_rotation(direction)
	
	if centering_time_left <= 0:
		centered = true
	
	
	#Calculate turn angle based on target angle
	if focus_object != null:
		var target_angle : Vector2
		var target_position = focus_object.get_global_transform().origin
		target_angle.x = -calculate_local_x_rotation(Player.get_global_transform().origin.direction_to(target_position))
		target_angle.y = calculate_global_y_rotation(Player.get_global_transform().origin.direction_to(target_position))
		
		turn_angle = target_angle - facing_angle
		turn_angle.x = bound_angle(turn_angle.x)
		turn_angle.y = bound_angle(turn_angle.y)
		if !centered:
			turn_angle = turn_angle/centering_time_left
	else:
		#Rotate to camera angle
		turn_angle = camera_angle_global - facing_angle
		turn_angle.x = bound_angle(turn_angle.x)
		turn_angle.y = bound_angle(turn_angle.y)
		if !centered:
			turn_angle = turn_angle/centering_time_left
	
	
	calculate_dive_velocity(delta)
	
	
	###Player Rotation
	#X Rotation
	rig_rotate_x_local(turn_angle.x)
	
	#Y Rotation
	Rig.transform = Rig.transform.rotated(Vector3.UP, turn_angle.y)
	
	
	###Decrement Timer
	if centering_time_left > 0:
		centering_time_left -= 1


#Locks rig to focus angle
func dive_strafe(delta):
	direction = get_input_direction()
	facing_angle.x = -calculate_local_x_rotation(facing_direction)
	facing_angle.y = calculate_global_y_rotation(facing_direction)
	camera_angle_global.x = -calculate_local_x_rotation(camera_direction)
	camera_angle_global.y = calculate_global_y_rotation(camera_direction)
	
	
	calculate_dive_velocity(delta)
	
	
	###Turn angle calculations
	turn_angle = camera_angle_global - facing_angle
	###Turn angle bounding
	turn_angle.x = bound_angle(turn_angle.x)
	turn_angle.y = bound_angle(turn_angle.y)
	
	###Turn radius limiting
	turn_angle.x = clamp(turn_angle.x, -turn_radius, turn_radius)
	turn_angle.y = clamp(turn_angle.y, -turn_radius, turn_radius)
	
	###Turn limit bounding
	if abs(facing_angle.x + turn_angle.x) > focus_angle_lim.x:
		turn_angle.x = (focus_angle_lim.x * sign(turn_angle.x)) - facing_angle.x
	
	if direction != Vector3(0,0,0):
		###Player Rotation
		#X Rotation
		rig_rotate_x_local(turn_angle.x)
		
		#Y Rotation
		Rig.transform = Rig.transform.rotated(Vector3.UP, turn_angle.y)


#Used to enter third person while moving
func dive_rotate_to_focus(delta):
	direction = get_input_direction()
	facing_angle.x = -calculate_local_x_rotation(facing_direction)
	facing_angle.y = calculate_global_y_rotation(facing_direction)
	camera_angle_global.x = -calculate_local_x_rotation(camera_direction)
	camera_angle_global.y = calculate_global_y_rotation(camera_direction)
	
	direction_angle.y = calculate_global_y_rotation(direction)
	
	calculate_dive_velocity(delta)
	
	turn_angle = camera_angle_global - facing_angle
	turn_angle.x = bound_angle(turn_angle.x)
	turn_angle.y = bound_angle(turn_angle.y)
	if view_change_time_left > 0:
		turn_angle = turn_angle/view_change_time_left
	
	###Player Rotation
	#X Rotation
	rig_rotate_x_local(turn_angle.x)
	
	#Y Rotation
	Rig.transform = Rig.transform.rotated(Vector3.UP, turn_angle.y)
	
	#Decrement Timer
	if view_change_time_left > 0:
		view_change_time_left -= 1
		
	if view_change_time_left <= 0:
		centered = true
		rotate_to_focus = false


func blend_move_anim():
	var time_scale
	var tween_time = 0.5
	
	
	move_blend_position = owner.get_node("AnimationTree").get("parameters/StateMachineMove/Swim/BlendSpace1D/blend_position")
	
	###Blend position tweening
	#Going from Idle to Swim_Forward
	if direction.length() > 0.0 and !is_equal_approx(move_blend_position, 1.0) and !active_tweens.has("parameters/StateMachineMove/Swim/BlendSpace1D/blend_position"):
		var seconds = (1.0 - move_blend_position) * tween_time
		#Transition to Swim
		owner.get_node("Tween").interpolate_property(owner.get_node("AnimationTree"), "parameters/StateMachineMove/Swim/BlendSpace1D/blend_position", move_blend_position, 1.0, seconds, Tween.TRANS_LINEAR)
		owner.get_node("Tween").start()
		
		add_active_tween("parameters/StateMachineMove/Swim/BlendSpace1D/blend_position")
	#Going from Swim_Forward to Idle
	elif direction.length() == 0.0 and acceleration_horizontal < 0.0 and !is_equal_approx(move_blend_position, 0.0):
		if active_tweens.has("parameters/StateMachineMove/Swim/BlendSpace1D/blend_position"):
			owner.get_node("Tween").stop(owner.get_node("AnimationTree"), "parameters/StateMachineMove/Swim/BlendSpace1D/blend_position")
		
		var seconds = (move_blend_position) * tween_time
		owner.get_node("Tween").interpolate_property(owner.get_node("AnimationTree"), "parameters/StateMachineMove/Swim/BlendSpace1D/blend_position", move_blend_position, 0.0, seconds, Tween.TRANS_LINEAR)
		owner.get_node("Tween").start()
		
		if !active_tweens.has("parameters/StateMachineMove/Swim/BlendSpace1D/blend_position"):
			add_active_tween("parameters/StateMachineMove/Swim/BlendSpace1D/blend_position")
	else:
		remove_active_tween("parameters/StateMachineMove/Swim/BlendSpace1D/blend_position")
	
	blend_swim_anim(move_blend_position)


func blend_swim_anim(current_blend_position):
	var time_scale
	var swim_time_scale
	
	
	#Swim_Idle time scale
	if is_equal_approx(current_blend_position, 0.0):
		current_blend_position = 0.0
		
		swim_time_scale = 1.0
		
		time_scale = swim_time_scale
	#Swim_Forward time scale
	elif current_blend_position > 0.0:
		swim_time_scale = (velocity_horizontal / speed_swim) * swim_anim_speed_max
		
		time_scale = swim_time_scale
	
	#Set blend position and time_scale in anim nodes
	owner.get_node("AnimationTree").set("parameters/StateMachineMove/Swim/BlendSpace1D/blend_position", current_blend_position)
	owner.get_node("AnimationTree").set("parameters/StateMachineMove/Swim/TimeScale/scale", time_scale)


func rig_rotate_x_local(angle):
	var transform = Rig.transform
	transform.origin.y -= player_height / 2.0
	Rig.transform = transform.rotated(facing_direction.cross(Vector3.UP).normalized(), angle)
	Rig.transform.origin.y += player_height / 2.0

