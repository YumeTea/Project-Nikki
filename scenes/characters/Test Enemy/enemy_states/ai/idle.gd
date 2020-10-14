extends "res://scenes/characters/Test Enemy/enemy_states/ai/ai.gd"


func initialize(init_values_dic):
	for value in init_values_dic:
		self[value] = init_values_dic[value]


#Initializes state, changes animation, etc
func enter():
	route_assign(Enemy.assigned_route)
	connect_enemy_signals()
	
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
func update(_delta):
	.update(_delta)


func _on_animation_finished(_anim_name):
	return


func _on_Timer_Route_timeout():
	route = route_advance(route)
























