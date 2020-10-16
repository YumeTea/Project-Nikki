extends "res://scenes/characters/Test Enemy/enemy_states/ai/ai.gd"


#Node Storage
onready var Timer_Engage = owner.get_node("State_Machine_AI/Engage/Timer_Engage")


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
func handle_input(event):
	.handle_input(event)


func handle_ai_input():
	.handle_ai_input()


#Acts as the _process method would
func update(_delta):
	#Clear AI input at start
	clear_ai_input()
	
	#Get AI inputs and emit them
	get_move_direction()
	get_look_direction()
	get_action_input()
	emit_signal("ai_input_changed", input)
	
	#Check if still targetting, else go back to idle state
	if !focus_object:
		emit_signal("finished", "idle")
	
	.update(_delta)


func _on_animation_finished(_anim_name):
	return


###AI INPUT FUNCTIONS###


func get_move_direction():
	var direction : Vector2
	
	if targetting:
		direction = Vector2(0,0)
		press_ai_input("left_stick", direction)


func get_look_direction():
	var direction : Vector2
	
	direction = Vector2(0,0)
	
	press_ai_input("right_stick", direction)


func get_action_input():
	press_ai_input("action_l2", "center_view")
	press_ai_input("action_y", "cast")





















