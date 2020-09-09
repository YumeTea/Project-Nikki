extends "res://scenes/Player/player_states/move/motion.gd"


#Creates output based on the input event passed in
func handle_input(event):
	if event.is_action_pressed("jump")  and event.get_device() == 0:
		if owner.is_on_floor():
			emit_signal("finished", "jump")
	
	.handle_input(event)


func update(delta):
	if owner.is_on_floor() == false:
		emit_signal("finished", "fall")
	
	.update(delta)

