extends "res://scenes/Player/player_states/move/in_air/in_air.gd"


func initialize(init_values_dic):
	for value in init_values_dic:
		self[value] = init_values_dic[value]


#Initializes state, changes animation, etc
func enter():
	velocity = Vector3(0,0,0)
	ledge_hang_height = ledge_height - Ledge_Grab_System.transform.origin.y
	ledge_grab_transform.origin.y = ledge_hang_height
	owner.global_transform = ledge_grab_transform
	center_to_wall()
	
	connect_player_signals()
	
	if owner.get_node("AnimationTree").get("parameters/StateMachineMove/playback").is_playing() == false:
		owner.get_node("AnimationTree").get("parameters/StateMachineMove/playback").start("Ledge_Hang")
	else:
		owner.get_node("AnimationTree").get("parameters/StateMachineMove/playback").travel("Ledge_Hang")
	.enter()


#Cleans up state, reinitializes values like timers
func exit():
	disconnect_player_signals()


#Creates output based on the input event passed in
func handle_input(event):
	.handle_input(event)


#Acts as the _process method would
func update(delta):
	.update(delta)


func on_animation_finished(_anim_name):
	return


func translate_to_ledge():
	#change focus angle
	#rotate camera(for first person)
	return


#Rotates rig to focus angle in centering time frames
#Used for changing view mode
func center_to_wall():
	var wall_angle_global : Vector3
	wall_angle_global.y = calculate_global_y_rotation(get_transform_direction(ledge_grab_transform))
	facing_angle.y = calculate_global_y_rotation(get_node_direction(Player.get_node("Rig")))
	
	
	turn_angle.y = wall_angle_global.y - facing_angle.y
	turn_angle.y = bound_angle(turn_angle.y)
#	if centering_time_left > 0:
#		turn_angle.y = turn_angle.y/centering_time_left
	
	
	owner.get_node("Rig").rotate_y(turn_angle.y)
	
	###Decrement Timer
	if centering_time_left > 0:
		centering_time_left -= 1
	
	if centering_time_left <= 0:
		centered = true
		rotate_to_focus = false





