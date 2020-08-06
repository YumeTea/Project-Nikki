extends "res://scenes/characters/Test Enemy/enemy_states/action/action.gd"


#Creates output based on the input event passed in
func handle_input(event):
#	if event.is_action_pressed("jump")  and event.get_device() == 0:
#		if owner.is_on_floor():
#			emit_signal("finished", "jump")
	.handle_input(event)


func handle_ai_input(input):
	if is_ai_action_pressed("cast", input):
		emit_signal("finished", "ground_cast")
	.handle_ai_input(input)


func update(delta):
	if owner.is_on_floor() == false:
		emit_signal("finished", "fall")
	.update(delta)

