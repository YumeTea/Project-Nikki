extends "res://scenes/Player/player_states/move/motion.gd"


func initialize(init_values_dic):
	for value in init_values_dic:
		self[value] = init_values_dic[value]


#Initializes state, changes animation, etc
func enter():
	connect_player_signals()


#Cleans up state, reinitializes values like timers
func exit():
	disconnect_player_signals()


#Creates output based on the input event passed in
func handle_input(_event):
	return


#Acts as the _process method would
func update(delta):
	calculate_movement_velocity(delta)
	.update(delta)


func on_animation_started(_anim_name):
	return


func on_animation_finished(_anim_name):
	return

