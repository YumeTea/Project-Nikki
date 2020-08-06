extends "res://scenes/characters/Test Enemy/enemy_states/on_ground/on_ground.gd"


func initialize(init_values_dic):
	for value in init_values_dic:
		self[value] = init_values_dic[value]


#Initializes state, changes animation, etc
func enter():
	centered = false
	centering_time_left = centering_time
	connect_enemy_signals()
#	owner.get_node("AnimationPlayer").play("Walk")


#Cleans up state, reinitializes values like timers
func exit():
#	owner.get_node("AnimationPlayer").stop()
	is_walking = false
	disconnect_enemy_signals()



#Creates output based on the input event passed in
func handle_input(event):
	.handle_input(event)


func handle_ai_input(input):
	.handle_ai_input(input)


#Acts as the _process method would
func update(delta):
	if !movement_locked:
		walk_free(delta)
	else:
		walk_locked(delta)
	if velocity == Vector3(0,0,0) and move_direction == Vector2(0,0):
		emit_signal("finished", "idle")
	.update(delta)


func _on_animation_finished(anim_name):
	return


