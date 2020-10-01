extends "res://scenes/characters/Test Enemy/enemy_states/move/motion.gd"


func enter():
	.enter()


func exit():
	.exit()


#Creates output based on the input event passed in
func handle_ai_input():
	if is_ai_action_pressed("jump", input):
		if owner.is_on_floor():
			if state_action != "Bow":
				emit_signal("finished", "jump")
	
	.handle_ai_input()


func update(delta):
	if in_water:
		if Enemy.global_transform.origin.y < (surface_height - enemy_height):
			emit_signal("finished", "swim")
	
	if owner.is_on_floor() == false and !snap_vector_is_colliding():
		emit_signal("finished", "fall")
	
	.update(delta)

