extends "res://scenes/characters/Test Enemy/enemy_states/ai/ai.gd"


#Engagement Variables
var engage_time = 10.0 #in seconds


func initialize(init_values_dic):
	for value in init_values_dic:
		self[value] = init_values_dic[value]


#Initializes state, changes animation, etc
func enter():
	cautious = true
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
func update(delta):
	#Clear AI input at start
	clear_ai_input()
	
	#Get AI inputs and emit them
	get_move_direction()
	get_look_direction()
	get_action_input(delta)
	emit_signal("ai_input_changed", input)
	
	
	if !focus_object:
		if Timer_Engage.is_stopped():
			Timer_Engage.start(10.0)
	elif focus_object:
		Timer_Engage.stop()
	
	.update(delta)


func _on_animation_finished(_anim_name):
	return


###AI INPUT FUNCTIONS###


func get_move_direction():
	var direction : Vector2 = Vector2(0,0)
	
	if targetting:
		direction = Vector2(0,0)
	
	press_ai_input("left_stick", direction)


func get_look_direction():
	var direction : Vector2
	
	if !targetting and suspicious:
		direction = look_to_point(seek_target_pos_last)
	else:
		direction = Vector2(0,0)
	
	press_ai_input("right_stick", direction)


func get_action_input(delta):
	if !targetting:
		seek_target(seek_target_name, delta)
		if closest_target:
			if closest_target.name == seek_target_name:
				press_ai_input("action_l1", "lock_target")
	elif targetting:
		press_ai_input("action_l2", "center_view")
		press_ai_input("action_y", "cast")


###SIGNAL FUNCTIONS###


func _on_Timer_Engage_timeout():
	emit_signal("finished", "cautious")








