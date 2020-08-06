extends "res://scenes/Player/player_states/on_ground/on_ground.gd"


#Initialization storage
var enter_velocity = Vector3()
var is_cast_jump


func initialize(init_values_dic):
	for value in init_values_dic:
		self[value] = init_values_dic[value]


#Initializes state, changes animation, etc
func enter():
	is_falling = false
	centered = false
	centering_time_left = centering_time
	connect_player_signals()
#	owner.get_node("AnimationPlayer").play("Walk")


#Cleans up state, reinitializes values like timers
func exit():
#	owner.get_node("AnimationPlayer").stop()
	is_walking = false
	disconnect_player_signals()



#Creates output based on the input event passed in
func handle_input(event):
	.handle_input(event)


#Acts as the _process method would
func update(delta):
	if !movement_locked:
		walk_free(delta)
	else:
		walk_locked(delta)
	if velocity == Vector3(0,0,0) and left_joystick_axis == Vector2(0,0):
		emit_signal("finished", "idle")
	.update(delta)


func _on_animation_finished(anim_name):
	return


