extends "res://scenes/characters/Test Enemy/enemy_states/move/in_air/in_air_enemy.gd"


func initialize(init_values_dic):
	for value in init_values_dic:
		self[value] = init_values_dic[value]


#Initializes state, changes animation, etc
func enter():
	speed = speed_aerial
	connect_enemy_signals()
	
#	if owner.get_node("AnimationTree").get("parameters/StateMachineMove/playback").is_playing() == false:
#		owner.get_node("AnimationTree").get("parameters/StateMachineMove/playback").start("Fall")
#	else:
#		owner.get_node("AnimationTree").get("parameters/StateMachineMove/playback").travel("Fall")
	.enter()


#Cleans up state, reinitializes values like timers
func exit():
	disconnect_enemy_signals()
	
	.exit()


#Creates output based on the input event passed in
func handle_input(event):
	.handle_input(event)


func handle_ai_input():
	.handle_ai_input()


#Acts as the _process method would
func update(delta):
	aerial_move(delta)
	.update(delta)
	
	if owner.is_on_floor():
		emit_signal("finished", "previous")


func on_animation_started(_anim_name):
	return


func on_animation_finished(_anim_name):
	return


func aerial_move(delta):
	direction = get_input_direction()
	
	calculate_aerial_velocity(delta)

