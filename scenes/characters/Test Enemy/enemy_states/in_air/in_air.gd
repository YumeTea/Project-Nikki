extends "res://scenes/characters/Test Enemy/enemy_states/action/action.gd"


func enter():
	reset_recenter()


#Creates output based on the input event passed in
func handle_input(event):
	.handle_input(event)


func handle_ai_input(input):
	if is_ai_action_just_pressed("cast", input):
		emit_signal("finished", "air_cast")
	.handle_ai_input(input)


func update(delta):
	.update(delta)
	if velocity.y < 0 and is_falling == false:
		emit_signal("started_falling", position.y)
		is_falling = true
	if cast_jump:
		cast_jump = false
		emit_signal("finished", "air_cast")

