extends "res://scenes/Player/player_states/action/action.gd"


func enter():
	reset_recenter()


#Creates output based on the input event passed in
func handle_input(event):
	if event.is_action_pressed("cast") and event.get_device() == 0:
		emit_signal("finished", "air_cast")
	.handle_input(event)


func update(delta):
	.update(delta)
	if velocity.y < 0 and is_falling == false:
		emit_signal("started_falling", position.y)
		is_falling = true
	if cast_jump:
		cast_jump = false
		emit_signal("finished", "air_cast")

