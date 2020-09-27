extends "res://scenes/Player/player_states/move/in_water/in_water.gd"


"Camera view skews on entering water in first person sometimes"


#Animation Variables
var swim_anim_speed_max = 1.5
const blend_lower_lim = 5.0 #Velocity where idle changes to all swim_forward


func initialize(init_values_dic):
	for value in init_values_dic:
		self[value] = init_values_dic[value]


#Initializes state, changes animation, etc
func enter():
#	surfaced_height = surface_height - player_height
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
	#Clear active tweens
	remove_active_tween("parameters/StateMachineMove/Walk/BlendSpace1D/blend_position")
	
	disconnect_player_signals()
	
	.exit()


#Creates output based on the input event passed in
func handle_input(event):
	if event.is_action_pressed("debug_[") and event.get_device() == 0:
		swim_anim_speed_max -= 0.1
		print("swim time_scale max: " + str(swim_anim_speed_max))
	if event.is_action_pressed("debug_]") and event.get_device() == 0:
		swim_anim_speed_max += 0.1
		print("swim time_scale max: " + str(swim_anim_speed_max))
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


func on_animation_started(_anim_name):
	return


func on_animation_finished(_anim_name):
	pass


func swim_third_person(delta):
	if !centering_view and !strafe_locked:
		swim_free(delta)
	elif centering_view:
		swim_locked_third_person(delta)
	elif strafe_locked:
		swim_strafe(delta)
	
	blend_move_anim()


func swim_first_person(delta):
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
	
	###Turn angle bounding
	next_turn_angle.y = bound_angle(next_turn_angle.y)
	
	if rotate_to_focus:
		swim_rotate_to_focus(delta) #for entering first person
	elif !centering_view and !strafe_locked and ((next_turn_angle.y < focus_angle_lim.y - deg2rad(2.0)) and (next_turn_angle.y > -focus_angle_lim.y + deg2rad(2.0))):
		swim_free(delta)
	elif centering_view:
		swim_locked_first_person(delta)
	else:
		swim_strafe(delta) #if trying to turn to where neck is over focus angle lim, strafe swim instead
	
	blend_move_anim()


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
	facing_angle.y = Rig.get_global_transform().basis.get_euler().y
	camera_angle_global.y = calculate_global_y_rotation(camera_direction)
	
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
	if view_change_time_left > 0:
		turn_angle.y = turn_angle.y/view_change_time_left
	
	###Player Rotation
	owner.get_node("Rig").rotate_y(turn_angle.y)
	
	#Decrement Timer
	if centering_time_left > 0:
		centering_time_left -= 1
		
	if centering_time_left <= 0:
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





