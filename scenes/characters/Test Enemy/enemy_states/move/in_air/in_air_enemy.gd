extends "res://scenes/characters/Test Enemy/enemy_states/move/motion.gd"


"""
Possible issue with fall damage after landing in water
"""

func enter():
	reset_recenter()
	
	.enter()

func exit():
	.exit()


#Creates output based on the input event passed in
func handle_ai_input():
	.handle_ai_input()


func update(delta):
	.update(delta)
	
	if in_water:
		if Enemy.global_transform.origin.y < (surface_height - enemy_height):
			emit_signal("finished", "swim")
	
	if velocity.y < 0 and is_falling == false:
		emit_signal("started_falling", position.y)
		is_falling = true
	if owner.is_on_floor():
		is_falling = false
		emit_signal("landed", height)

