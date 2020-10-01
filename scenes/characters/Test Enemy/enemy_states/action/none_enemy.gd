extends "res://scenes/characters/Test Enemy/enemy_states/action/action.gd"


func initialize(init_values_dic):
	for value in init_values_dic:
		self[value] = init_values_dic[value]


#Initializes state, changes animation, etc
func enter():
	connect_enemy_signals()
	.enter()


#Cleans up state, reinitializes values like timers
func exit():
	disconnect_enemy_signals()
	.exit()


#Creates output based on the input event passed in
func handle_ai_input():
	#Check for inputs that enter new states first
	#Ground only actions
	if state_move in ground_states:
		if is_ai_action_pressed("cast", input):
			emit_signal("finished", "cast")
	
	.handle_ai_input()


#Acts as the _process method would
func update(delta):
	.update(delta)


func on_animation_started(_anim_name):
	return


func on_animation_finished(_anim_name):
	return






