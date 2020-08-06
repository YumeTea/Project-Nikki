extends "res://scenes/characters/Test Enemy/enemy_states/in_air/in_air.gd"


#Jump Variables
var jump_strength = 20


func initialize(init_values_dic):
	for value in init_values_dic:
		self[value] = init_values_dic[value]


#Initializes state, changes animation, etc
func enter():
	snap_vector = Vector3(0,0,0)
	if owner.is_on_floor():
		velocity.y = jump_strength #only jump if on the floor
	is_falling = false
	connect_enemy_signals()


#Cleans up state, reinitializes values like timers
func exit():
	if cast_jump == false: #snap_vector needs to be off going into air_cast
		snap_vector = snap_vector_default
	is_falling = false
	disconnect_enemy_signals()


#Creates output based on the input event passed in
func handle_input(event):
	.handle_input(event)


func handle_ai_input(input):
	.handle_ai_input(input)


#Acts as the _process method would
func update(delta):
	.update(delta)
	if owner.is_on_floor():
		is_falling = false
		emit_signal("landed", height)
		emit_signal("finished", "previous")


func _on_animation_finished(anim_name):
	return


func jump(delta):
	return

