extends "res://scenes/characters/Test Enemy/enemy_states/ai/ai.gd"


func initialize(init_values_dic):
	for value in init_values_dic:
		self[value] = init_values_dic[value]


#Initializes state, changes animation, etc
func enter():
	if route == []:
		route_assign(Enemy.assigned_route)
	else:
		move_to(route[0])
	
	targetting = false
	suspicious = false
	
	connect_enemy_signals()
	
	.enter()


#Cleans up state, reinitializes values like timers
func exit():
	Timer_Route.stop()
	
	disconnect_enemy_signals()
	
	.exit()


#Creates output based on the input event passed in
func handle_input(event):
	.handle_input(event)


func handle_ai_input():
	.handle_ai_input()


#Acts as the _process method would
func update(delta):
	#Clear AI input at start
	clear_ai_input()
	
	#Get AI inputs and emit them
	get_move_direction()
	get_look_direction()
	get_action_input(delta)
	emit_signal("ai_input_changed", input)
	
	#If targetting, engage target
	if focus_object:
		emit_signal("finished", "engage")
	
	.update(delta)


func _on_animation_finished(_anim_name):
	return


func _on_Timer_Route_timeout():
	route = route_advance(route)


###AI INPUT FUNCTIONS###


func get_move_direction():
	var direction : Vector2
	
	if suspicious:
		direction = Vector2(0,0)
	elif !targetting and advancing:
		direction = calc_target_path()
		press_ai_input("left_stick", direction / 2.0)
	else:
		direction = calc_target_path()
		press_ai_input("left_stick", direction / 2.0)


func get_look_direction():
	var direction : Vector2
	
	if !targetting and suspicious:
		direction = look_to_point(seek_target_pos_last) #look at suspitious object
	elif !targetting and !advancing:
		direction = Vector2(sin(OS.get_time()["second"]/2), 0)
	elif advancing:
		direction = look_to_point(path[path_point])
	
	press_ai_input("right_stick", direction)


func get_action_input(delta):
	if !targetting:
		seek_target(seek_target_name, delta)
		if closest_target:
			if closest_target.name == seek_target_name and Awareness.threat_level >= 100.0:
				press_ai_input("action_l1", "lock_target")


















