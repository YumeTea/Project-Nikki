extends "res://scenes/characters/Test Enemy/enemy_states/ai/ai.gd"


func initialize(init_values_dic):
	for value in init_values_dic:
		self[value] = init_values_dic[value]


#Initializes state, changes animation, etc
func enter():
	suspicious = false
	targetting = false
	
	if !owner.get_node("Rig/AnimationPlayer").is_playing():
		owner.get_node("Rig/AnimationPlayer").play("Suspicious")
	
	connect_enemy_signals()
	
	.enter()


#Cleans up state, reinitializes values like timers
func exit():
	Timer_Route.stop()
	
	owner.get_node("Rig/Question_Mark").visible = false
	
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
	
	Awareness.threat_decrease(0.1, delta)
	
	if Awareness.threat_level <= 0.0:
		emit_signal("finished", "idle")
	if suspicious:
		emit_signal("finished", "suspicious")
	
	.update(delta)


func _on_animation_finished(_anim_name):
	return


###AI INPUT FUNCTIONS###


func get_move_direction():
	var direction : Vector2
	
	if !targetting and advancing:
		direction = calc_target_path() / 4.0
	else:
		direction = calc_target_path() / 4.0
	
	press_ai_input("left_stick", direction)


func get_look_direction():
	var direction : Vector2
	
	if !targetting and !advancing:
		direction = Vector2(sin(OS.get_time()["second"]/2), 0)
	elif advancing:
		direction = look_to_point(path[path_point])
	
	press_ai_input("right_stick", direction)


func get_action_input(delta):
	if !targetting:
		seek_target(seek_target_name, delta)


###SIGNAL FUNCTIONS###
func _on_Timer_Route_timeout():
	if !route.empty():
		route = route_advance(route)


