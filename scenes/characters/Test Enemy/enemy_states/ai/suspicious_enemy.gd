extends "res://scenes/characters/Test Enemy/enemy_states/ai/ai.gd"


func initialize(init_values_dic):
	for value in init_values_dic:
		self[value] = init_values_dic[value]


#Initializes state, changes animation, etc
func enter():
	advancing = false
	
	if !owner.get_node("Rig/AnimationPlayer").is_playing():
		owner.get_node("Rig/AnimationPlayer").play("Suspicious")
	
	connect_enemy_signals()
	
	.enter()


#Cleans up state, reinitializes values like timers
func exit():
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
	
	#Go to idle ai state if threat level is 0%
	if Awareness.threat_level <= 0.0:
		emit_signal("finished", "idle")
	
	#Engage target once locked on
	if focus_object:
		emit_signal("finished", "engage")
	
	#Move to suspected target location if past a certain threat level
	if Awareness.threat_level >= 50.0 and !advancing:
		move_to(seek_target_pos_last)
	
	.update(delta)


func _on_animation_finished(_anim_name):
	return


###AI INPUT FUNCTIONS###


func get_move_direction():
	var direction : Vector2
	
	if !targetting and advancing and !(Awareness.threat_level >= 100.0):
		direction = calc_target_path() / 2.0
	else:
		direction = Vector2(0,0)
	
	press_ai_input("left_stick", direction)


func get_look_direction():
	var direction
	
	if advancing and !(Awareness.threat_level >= 100.0):
		direction = look_to_point(path[path_point])
	else:
		direction = look_to_point(seek_target_pos_last)
	
	press_ai_input("right_stick", direction)


func get_action_input(delta):
	if !targetting:
		seek_target(seek_target_name, delta)
	
	#If threat level is 100% and the target to be locked is the seek_target, lock on
	if closest_target:
		if closest_target.name == seek_target_name and Awareness.threat_level >= 100.0:
			if !(is_ai_action_just_pressed("lock_target", input)):
				press_ai_input("action_l1", "lock_target")


###SIGNAL FUNCTIONS###


func _on_Timer_Suspicious_timeout():
	if cautious:
		emit_signal("finished", "cautious")





