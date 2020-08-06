extends Node


signal finished(next_state_name)


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
	return


func _on_animation_finished(anim_name):
	return

