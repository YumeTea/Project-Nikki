extends "res://scenes/Player/player_states/move/motion.gd"


func initialize(init_values_dic):
	for value in init_values_dic:
		self[value] = init_values_dic[value]


#Initializes state, changes animation, etc
func enter():
#	owner.get_node("AnimationPlayer").play("Die")
	return


#Cleans up state, reinitializes values like timers
func exit():
	return


#Creates output based on the input event passed in
func handle_input(_event):
	return


#Acts as the _process method would
func update(_delta):
	return


func on_animation_started(_anim_name):
	return


func on_animation_finished(_anim_name):
	return

