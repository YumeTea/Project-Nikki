extends "res://scenes/Player/player_states/move/on_ground/on_ground.gd"


const idle_default_blend = 0
const idle_bow_blend = -0.8


func initialize(init_values_dic):
	for value in init_values_dic:
		self[value] = init_values_dic[value]


#Initializes state, changes animation, etc
func enter():
	direction = Vector3(0,0,0)
	left_joystick_axis = Vector2(0,0)
	is_moving = false
	is_falling = false
	connect_player_signals()
	
	if owner.get_node("AnimationTree").get("parameters/StateMachineLowerBody/playback").is_playing() == false:
		owner.get_node("AnimationTree").get("parameters/StateMachineLowerBody/playback").start("Idle")
	else:
		owner.get_node("AnimationTree").get("parameters/StateMachineLowerBody/playback").travel("Idle")


#Cleans up state, reinitializes values like timers
func exit():
	#Clear active tweens
	remove_active_tween("parameters/StateMachineLowerBody/Idle/BlendSpace1D/blend_position")
	
	disconnect_player_signals()


#Creates output based on the input event passed in
func handle_input(event):
#	if event.is_action_pressed("debug_input") and event.get_device() == 0:
#		print(owner.get_node("AnimationTree").get("parameters/StateMachineLowerBody/Idle/BlendSpace1D/blend_position"))
	.handle_input(event)


#Acts as the _process method would
func update(delta):
	if get_input_direction() != Vector3(0,0,0):
		emit_signal("finished", "walk") #emit the finished signal and input walk as next state (from state.gd)
	
	if view_mode == "third_person":
		idle_third_person()
	elif view_mode == "first_person":
		idle_first_person()
	
	.update(delta)

func on_animation_finished(_anim_name):
	pass


func idle_third_person():
	if rotate_to_focus:
		center_to_focus()
	elif centering_view:
		rotate_to_target_third_person()
	elif strafe_locked:
		lock_to_focus()
	
	blend_idle_anim()


func idle_first_person():
	if rotate_to_focus:
		center_to_focus()
	elif centering_view:
		rotate_to_target_first_person()
	elif strafe_locked:
		lock_to_focus()
	
	blend_idle_anim()


#Rotates rig to target or rig facing angle in centering_time frames
func rotate_to_target_third_person():
	facing_angle.y = owner.get_node("Rig").get_global_transform().basis.get_euler().y
	
	if centering_time_left <= 0:
		centered = true
	
	
	if focus_object != null:
		var target_position = focus_object.get_global_transform().origin
		var target_angle = Vector2()
		target_angle.y = calculate_global_y_rotation(owner.get_global_transform().origin.direction_to(target_position))
		
		turn_angle.y = target_angle.y - facing_angle.y
		turn_angle.y = bound_angle(turn_angle.y)
		if !centered:
			turn_angle.y = turn_angle.y/centering_time_left
	else:
		turn_angle.y = 0
	
	emit_signal("center_view", turn_angle.y)
	
	owner.get_node("Rig").rotate_y(turn_angle.y)
	
	
	###Decrement Timer
	if centering_time_left > 0:
		centering_time_left -= 1


#Rotates rig to target or focus angle in centering_time frames
func rotate_to_target_first_person():
	facing_angle.y = owner.get_node("Rig").get_global_transform().basis.get_euler().y
	
	if centering_time_left <= 0:
		centered = true
	
	
	if focus_object != null:
		var target_position = focus_object.get_global_transform().origin
		var target_angle = Vector2()
		target_angle.y = calculate_global_y_rotation(owner.get_global_transform().origin.direction_to(target_position))
		
		turn_angle.y = target_angle.y - facing_angle.y
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
	
	owner.get_node("Rig").rotate_y(turn_angle.y)
	
	
	###Decrement Timer
	if centering_time_left > 0:
		centering_time_left -= 1


#Rotates rig to focus angle limited to turn_radius
func lock_to_focus():
	facing_angle.y = owner.get_node("Rig").get_global_transform().basis.get_euler().y
	camera_angle_global.y = calculate_global_y_rotation(camera_direction)
	
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


#Rotates rig to focus angle in centering time frames
func center_to_focus():
	camera_angle_global.y = calculate_global_y_rotation(camera_direction)
	facing_angle.y = calculate_global_y_rotation(get_node_direction(Player.get_node("Rig")))
	
	
	turn_angle.y = camera_angle_global.y - facing_angle.y
	turn_angle.y = bound_angle(turn_angle.y)
	turn_angle.y = turn_angle.y/centering_time_left
	
	owner.get_node("Rig").rotate_y(turn_angle.y)
	
	###Decrement Timer
	if centering_time_left > 0:
		centering_time_left -= 1
	
	if centering_time_left <= 0:
		centered = true
		rotate_to_focus = false
		emit_signal("entered_new_view", view_mode)


func blend_idle_anim():
	###Idle Blending
	#Set move_blend_position in case coming from walk
#	owner.get_node("AnimationTree").set("parameters/StateMachineLowerBody/Walk/BlendSpace1D/blend_position", move_blend_position)
	
	move_blend_position = owner.get_node("AnimationTree").get("parameters/StateMachineLowerBody/Idle/BlendSpace1D/blend_position")
	
	#Bow Idle Blend
	if state_action == "Bow":
		if move_blend_position != idle_bow_blend and !active_tweens.has("parameters/StateMachineLowerBody/Idle/BlendSpace1D/blend_position"):
			owner.get_node("Tween").interpolate_property(owner.get_node("AnimationTree"), "parameters/StateMachineLowerBody/Idle/BlendSpace1D/blend_position", move_blend_position, idle_bow_blend, 0.25, Tween.TRANS_LINEAR)
			owner.get_node("Tween").start()
			add_active_tween("parameters/StateMachineLowerBody/Idle/BlendSpace1D/blend_position")
		elif move_blend_position == idle_bow_blend and active_tweens.has("parameters/StateMachineLowerBody/Idle/BlendSpace1D/blend_position"):
			remove_active_tween("parameters/StateMachineLowerBody/Idle/BlendSpace1D/blend_position")
	
	#None Idle Blend
	else:
		#Animate blend to default idle blend position if coming out of bow state
		if is_equal_approx(move_blend_position, idle_bow_blend):
			owner.get_node("Tween").interpolate_property(owner.get_node("AnimationTree"), "parameters/StateMachineLowerBody/Idle/BlendSpace1D/blend_position", move_blend_position, 0.0, 0.5, Tween.TRANS_LINEAR)
			owner.get_node("Tween").start()
			add_active_tween("parameters/StateMachineLowerBody/Idle/BlendSpace1D/blend_position")
		#Clear active tweens if not animating blend position between states
		elif move_blend_position > idle_default_blend or is_equal_approx(move_blend_position, idle_default_blend):
			remove_active_tween("parameters/StateMachineLowerBody/Idle/BlendSpace1D/blend_position")



















