extends "res://scenes/Player/player_states/move/motion.gd"


func enter():
	reset_recenter()


#Creates output based on the input event passed in
func handle_input(event):
	.handle_input(event)


func update(delta):
	.update(delta)
	if velocity.y < 0 and is_falling == false:
		emit_signal("started_falling", position.y)
		is_falling = true
	if owner.is_on_floor():
		is_falling = false
		emit_signal("landed", height)

