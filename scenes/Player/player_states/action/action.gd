extends "res://scenes/Player/player_states/interaction/interaction.gd"


#Node Storage
onready var world = owner.owner
onready var Player = owner
onready var Rig = owner.get_node("Rig/Skeleton")
onready var animation_state_machine_action = owner.get_node("AnimationTree").get("parameters/StateMachineUpperBody/playback")

#Initialized Values Storage
var initialized_values = {}

#Equipment Storage
var equipped_items = null
var equipped_weapon = null
var equipped_bow = null
var equipped_magic = null

#Player Flags
var can_void = true

#Player Variables
var focus_angle = Vector2()

###Projectile Variables
var projectile
var RIGID_PROJ = preload("res://scenes/Player/attacks/magic/projectiles/rigid_projectile_test/rigid_projectile.tscn")
var MAGIC_ORB = preload("res://scenes/Player/attacks/magic/projectiles/magic_orb/magic_orb.tscn")
var projectile_time = 0
var projectile_count = 0

#Action flags
var move_state_changed
var is_casting = false
var finished_casting = false


#Initializes state, changes animation, etc
func enter():
	owner.get_node("AnimationTree").connect("animation_started", self, "on_animation_started")
	owner.get_node("AnimationTree").connect("animation_finished", self, "on_animation_finished")


#Cleans up state, reinitializes values like timers
func exit():
	owner.get_node("AnimationTree").disconnect("animation_started", self, "on_animation_started")
	owner.get_node("AnimationTree").disconnect("animation_finished", self, "on_animation_finished")


#Creates output based on the input event passed in
func handle_input(event):
#	if event.is_action_pressed("debug_input") and event.get_device() == 0:
#		owner.get_node("Tween").start()
	.handle_input(event)


#Acts as the _process method would
func update(delta):
	.update(delta)


func on_animation_finished(_anim_name):
	return


#Starts anim and calls function to animate blend amount
func start_anim_1d_action(anim_name, action_blend_pos, fade_time):
	anim_fade_in_1d_action(fade_time, action_blend_pos)
	owner.get_node("AnimationTree").set("parameters/TimeScaleAction/scale", 1.0)
	owner.get_node("AnimationTree").get("parameters/StateMachineAction/playback").start(anim_name)


#Animates blend amount for StateMachineAction
func anim_fade_in_1d_action(fade_time, action_blend_pos):
	var current_blend_pos = owner.get_node("AnimationTree").get("parameters/UpperBodyxAction/blend_amount")
	
	#Check if blend amount is already being animated and interrupt it
	if active_tweens.has("parameters/UpperBodyxAction/blend_amount"):
		owner.get_node("Tween").stop(owner.get_node("AnimationTree"), "parameters/UpperBodyxAction/blend_amount")
		remove_active_tween("parameters/UpperBodyxAction/blend_amount")
	
	#Start blending fade in if not already doing so
	if current_blend_pos != action_blend_pos and !active_tweens.has("parameters/UpperBodyxAction/blend_amount"):
		owner.get_node("Tween").interpolate_property(owner.get_node("AnimationTree"), "parameters/UpperBodyxAction/blend_amount", current_blend_pos, action_blend_pos, fade_time, Tween.TRANS_LINEAR)
		owner.get_node("Tween").start()
		add_active_tween("parameters/UpperBodyxAction/blend_amount")


func anim_fade_out_1d_action(fade_time):
	var current_blend_pos = owner.get_node("AnimationTree").get("parameters/UpperBodyxAction/blend_amount")
	
	#Check if blend amount is already being animated and interrupt it
	if active_tweens.has("parameters/UpperBodyxAction/blend_amount"):
		owner.get_node("Tween").stop_all()
		remove_active_tween("parameters/UpperBodyxAction/blend_amount")
	
	#Set tween values for blend fade out
	owner.get_node("Tween").interpolate_property(owner.get_node("AnimationTree"), "parameters/UpperBodyxAction/blend_amount", current_blend_pos, 0.0, fade_time, Tween.TRANS_LINEAR)
	owner.get_node("Tween").start()
	add_active_tween("parameters/UpperBodyxAction/blend_amount")


func set_initialized_values(init_values_dic):
	for value in init_values_dic:
		init_values_dic[value] = self[value]


func connect_player_signals():
	owner.connect("focus_target", self, "_on_Player_focus_target_changed")
	owner.inventory.connect("equipped_items_changed", self, "_on_Player_equipped_items_changed")
	owner.get_node("State_Machine_Move").connect("move_state_changed", self, "_on_move_state_changed")
	owner.get_node("State_Machine_Action").connect("initialized_values_dic_set", self, "_on_State_Machine_Action_initialized_values_dic_set")
	owner.get_node("Camera_Rig").connect("focus_direction_changed", self, "_on_Camera_Rig_focus_direction_changed")
	owner.get_node("Attributes/Health").connect("health_depleted", self, "_on_death")
	
	#World Signals
#	owner.connect("entered_area", self, "_on_environment_area_entered")
#	owner.connect("exited_area", self, "_on_environment_area_exited")
	if owner.owner:
		owner.owner.connect("player_voided", self, "_on_voided")


func disconnect_player_signals():
	owner.disconnect("focus_target", self, "_on_Player_focus_target_changed")
	owner.inventory.disconnect("equipped_items_changed", self, "_on_Player_equipped_items_changed")
	owner.get_node("State_Machine_Move").disconnect("move_state_changed", self, "_on_move_state_changed")
	owner.get_node("State_Machine_Action").disconnect("initialized_values_dic_set", self, "_on_State_Machine_Action_initialized_values_dic_set")
	owner.get_node("Camera_Rig").disconnect("focus_direction_changed", self, "_on_Camera_Rig_focus_direction_changed")
	owner.get_node("Attributes/Health").disconnect("health_depleted", self, "_on_death")
	
	#World Signals
#	owner.connect("entered_area", self, "_on_environment_area_entered")
#	owner.connect("exited_area", self, "_on_environment_area_exited")
	if owner.owner:
		owner.owner.disconnect("player_voided", self, "_on_voided")


###PLAYER SIGNAL FUNCTIONS### 

func _on_Player_focus_target_changed(target_pos_node):
	focus_object = target_pos_node


func _on_Player_equipped_items_changed(equipped_items_dict):
	equipped_items = equipped_items_dict


func _on_move_state_changed(move_state):
	state_move = move_state
	move_state_changed = true
	
	if state_move == "Swim":
		emit_signal("finished", "none")


func _on_State_Machine_Action_initialized_values_dic_set(init_values_dic):
	initialized_values = init_values_dic


func _on_Camera_Rig_focus_direction_changed(direction):
	focus_direction = direction


func _on_death(death):
	if death:
		emit_signal("finished", "death")


###WORLD SIGNAL FUNCTIONS###

#func _on_environment_area_entered(area_type, surface_height):
#	if area_type == "Water":
#		in_water = true
#
#
#func _on_environment_area_exited():
#	if area_type == "Water":
#		in_water = false


func _on_voided(voided):
	if voided and can_void:
		emit_signal("finished", "void")
		can_void = false




