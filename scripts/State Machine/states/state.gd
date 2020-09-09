extends Node


signal finished(next_state_name)


func initialize(init_values_dic):
	for value in init_values_dic:
		self[value] = init_values_dic[value]


#Initializes state, changes animation, etc
func enter():
	return


#Cleans up state, reinitializes values like timers
func exit():
	return


#Creates output based on the input event passed in
func handle_input(_event):
	return


func handle_ai_input(_input):
	return


#Acts as the _process method would
func update(_delta):
	return


func _on_animation_finished(_anim_name):
	return

