extends "res://scripts/State Machine/states/state.gd"


"-Find a better method to connect to signals from current level"




signal position_changed(current_position)
signal velocity_changed(current_velocity)
signal started_falling(fall_height)
signal landed(landing_height)
signal center_view(turn_angle)
signal lock_target


###Node Storage
onready var camera = owner.get_node("Camera_Rig/Pivot/Camera_Position") #should get camera position a different way
var focus_target_pos = null

#Initialized Values Storage
var initialized_values = {}

#World Interaction Variables
var fall_height
var land_height

###Player Variables
var facing_angle #Goes from -pi > 0 > pi

###Movement Variables
#Centering Variables
var centering_time = 6 #in frames
var centering_time_left = 0

#Player Flags
var targetting = false
var movement_locked = false
var can_void = true
var is_falling = false
var centering = false
var centered = false

#Initializes state, changes animation, etc
func enter():
	owner.get_node("AnimationPlayer").connect("animation_finished", self, "_on_animation_finished")

#Cleans up state, reinitializes values like timers
func exit():
	owner.get_node("AnimationPlayer").disconnect("animation_finished", self, "_on_animation_finished")


#Creates output based on the input event passed in
func handle_input(event):
	if event.is_action_pressed("lock_target") and event.get_device() == 0:
		if !targetting:
			targetting = true
		else:
			targetting = false


#Acts as the _process method would
func update(delta):
	return


func _on_animation_finished(anim_name):
	return


func connect_player_signals():
	owner.connect("focus_target", self, "_on_focus_target_changed")
	owner.get_node("State_Machine").connect("initialized_values_dic_set", self, "_on_initialized_values_dic_set")
	owner.get_node("Attributes/Health").connect("health_depleted", self, "_on_death")
	owner.get_node("Camera_Rig").connect("view_locked", self, "_on_view_locked")
	if owner.owner:
		owner.owner.connect("player_voided", self, "_on_voided")


func disconnect_player_signals():
	owner.disconnect("focus_target", self, "_on_focus_target_changed")
	owner.get_node("State_Machine").disconnect("initialized_values_dic_set", self, "_on_initialized_values_dic_set")
	owner.get_node("Attributes/Health").disconnect("health_depleted", self, "_on_death")
	owner.get_node("Camera_Rig").disconnect("view_locked", self, "_on_view_locked")
	if owner.owner:
		owner.owner.disconnect("player_voided", self, "_on_voided")


func _on_focus_target_changed(target_pos_node):
	focus_target_pos = target_pos_node


func _on_initialized_values_dic_set(init_values_dic):
	initialized_values = init_values_dic


func _on_view_locked(is_view_locked, time_left):
	movement_locked = is_view_locked
#	centering_time_left = time_left
	if !movement_locked:
		centered = false


func _on_voided(voided):
	if voided and can_void:
		emit_signal("finished", "void")
		can_void = false


func _on_death(death):
	if death:
		emit_signal("finished", "death")

