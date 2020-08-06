extends "res://scripts/State Machine/states/state.gd"


"	-Find a better method to connect to signals from current level"



signal position_changed(current_position)
signal velocity_changed(current_velocity)
signal facing_direction_changed(facing_direction)
signal started_falling(fall_height)
signal landed(landing_height)
signal center_view
signal lock_target



###Node Storage
onready var head = owner.get_node("Camera_Rig/Pivot") #should get camera position a different way
var focus_target_pos = null

#AI Input Storage
var input = {}

#Initialized State Values
var initialized_values = {}

#World Interaction Variables
var fall_height
var land_height

#Enemy Variables
var facing_angle #Goes from -pi > 0 > pi

###Movement Variables
#Centering Variables
var centering_time = 6 #in frames
var centering_time_left = 0

#Enemy Flags
var targetting = false
var movement_locked = false
var can_void = true
var is_walking
var is_falling = false
var centering = false
var centered = false


#Creates output based on the input event passed in
func handle_input(event):
	return


func handle_ai_input(input):
	return


#Acts as the _process method would
func update(delta):
	return


func _on_animation_finished(anim_name):
	return


func is_ai_action_pressed(action, input_dic):
	for input_name in input_dic:
		if typeof(input_dic[input_name]) == typeof(action):
			if input[input_name] == action:
				return true
	
	return false


func connect_enemy_signals():
	owner.connect("ai_input_changed", self, "_on_ai_input_changed")
	owner.connect("focus_target", self, "_on_focus_target_changed")
	owner.get_node("State_Machine").connect("initialized_values_dic_set", self, "_on_initialized_values_dic_set")
	owner.get_node("Attributes/Health").connect("health_depleted", self, "_on_death")
	owner.get_node("Camera_Rig").connect("view_locked", self, "_on_view_locked")


func disconnect_enemy_signals():
	owner.disconnect("ai_input_changed", self, "_on_ai_input_changed")
	owner.disconnect("focus_target", self, "_on_focus_target_changed")
	owner.get_node("State_Machine").disconnect("initialized_values_dic_set", self, "_on_initialized_values_dic_set")
	owner.get_node("Attributes/Health").disconnect("health_depleted", self, "_on_death")
	owner.get_node("Camera_Rig").disconnect("view_locked", self, "_on_view_locked")


func _on_ai_input_changed(inputs):
	input = inputs


func _on_focus_target_changed(target_pos_node):
	if target_pos_node != null:
		focus_target_pos = target_pos_node
		targetting = true
	else:
		focus_target_pos = target_pos_node
		targetting = false


func _on_view_locked(is_view_locked, time_left):
	movement_locked = is_view_locked
	centering_time_left = time_left
	if !movement_locked:
		centered = false


func _on_initialized_values_dic_set(init_values_dic):
	initialized_values = init_values_dic


func _on_voided(voided):
	if voided and can_void:
		emit_signal("finished", "void")
		can_void = false


func _on_death(death):
	if death:
		emit_signal("finished", "death")

