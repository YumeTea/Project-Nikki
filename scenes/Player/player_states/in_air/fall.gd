extends "res://scenes/Player/player_states/in_air/in_air.gd"


func initialize(init_values_dic):
	for value in init_values_dic:
		self[value] = init_values_dic[value]


#Initializes state, changes animation, etc
func enter():
	.enter()
	connect_player_signals()


#Cleans up state, reinitializes values like timers
func exit():
	disconnect_player_signals()


#Creates output based on the input event passed in
func handle_input(event):
	.handle_input(event)


#Acts as the _process method would
func update(delta):
	.update(delta)
	if owner.is_on_floor():
		is_falling = false
		emit_signal("landed", height)
		emit_signal("finished", "previous")


func _on_animation_finished(anim_name):
	return

