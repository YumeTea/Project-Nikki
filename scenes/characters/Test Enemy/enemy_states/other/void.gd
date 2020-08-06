extends "res://scenes/characters/Test Enemy/enemy_states/motion.gd"


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
func handle_input(event):
	return


func handle_ai_input(input):
	return


#Acts as the _process method would
func update(delta):
	calculate_movement_velocity(delta)
	.update(delta)


func _on_animation_finished(anim_name):
	return

