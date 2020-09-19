extends "res://scenes/Player/player_states/move/in_air/in_air.gd"


func initialize(init_values_dic):
	for value in init_values_dic:
		self[value] = init_values_dic[value]


#Initializes state, changes animation, etc
func enter():
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

