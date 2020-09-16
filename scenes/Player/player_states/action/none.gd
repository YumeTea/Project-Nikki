extends "res://scenes/Player/player_states/action/action.gd"

"""
replace _on_Player_equipped_items_changed with dictionaries for left/right hand in inventory_resource
"""



onready var skeleton = owner.get_node("Rig/Skeleton")
onready var left_bicep = skeleton.find_bone("bicep_l")


func initialize(init_values_dic):
	for value in init_values_dic:
		self[value] = init_values_dic[value]


#Initializes state, changes animation, etc
func enter():
	connect_player_signals()
	.enter()

#Cleans up state, reinitializes values like timers
func exit():
	owner.get_node("AnimationTree").set("parameters/MovexLeftHand/blend_amount", 0.0)
	disconnect_player_signals()
	.exit()


#Creates output based on the input event passed in
func handle_input(event):
	#Check for inputs that enter new states first
	if state_move in ground_states:
		if event.is_action_pressed("cast") and event.get_device() == 0:
			emit_signal("finished", "cast")
		if event.is_action_pressed("draw_bow") and event.get_device() == 0:
			if equipped_bow != null:
				emit_signal("finished", "bow")
	
	if event.is_action_pressed("bow_next") and event.get_device() == 0:
		owner.inventory.next_item("Bow")
		equipped_items = owner.inventory.equipped_items
		cycle_equipment()
		
	
	if event.is_action_pressed("arrow_next") and event.get_device() == 0:
		owner.inventory.next_item("Arrow")
		equipped_items = owner.inventory.equipped_items
	if event.is_action_pressed("arrow_previous") and event.get_device() == 0:
		owner.inventory.previous_item("Arrow")
		equipped_items = owner.inventory.equipped_items
	
#	if event.is_action_pressed("debug_input") and event.get_device() == 0:
#		print("MovexAction blend: " + str(owner.get_node("AnimationTree").get("parameters/MovexAction/blend_amount")))
	
	.handle_input(event)


#Acts as the _process method would
func update(delta):
	#Change left arm anim to match held item
	set_left_hand_anim()
	
	.update(delta)


func on_animation_started(_anim_name):
	return


func on_animation_finished(_anim_name):
	return


func set_left_hand_anim():
	if equipped_bow:
		if !owner.get_node("AnimationTree").get("parameters/StateMachineLeftHand/playback").is_playing():
			owner.get_node("AnimationTree").get("parameters/StateMachineLeftHand/playback").start("Bow_Hold")
		owner.get_node("AnimationTree").set("parameters/MovexLeftHand/blend_amount", 1.0)
	else:
		owner.get_node("AnimationTree").set("parameters/MovexLeftHand/blend_amount", 0.0)






