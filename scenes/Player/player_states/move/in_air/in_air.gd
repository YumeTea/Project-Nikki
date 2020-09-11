extends "res://scenes/Player/player_states/move/motion.gd"

"""
Possible issue with fall damage after landing in water
"""

func enter():
	reset_recenter()


#Creates output based on the input event passed in
func handle_input(event):
	.handle_input(event)


func update(delta):
	.update(delta)
	
	if in_water:
		if Player.global_transform.origin.y < surface_height - (player_center / 3.0):
			emit_signal("finished", "swim")
	
	if velocity.y < 0 and is_falling == false:
		emit_signal("started_falling", position.y)
		is_falling = true
	if owner.is_on_floor():
		is_falling = false
		emit_signal("landed", height)

