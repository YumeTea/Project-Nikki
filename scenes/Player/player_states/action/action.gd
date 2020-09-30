extends "res://scenes/Player/player_states/interaction/interaction.gd"


#Node Storage
onready var world = get_tree().current_scene
onready var Player = owner
onready var Rig = owner.get_node("Rig/Skeleton")

#Initialized Values Storage
var initialized_values = {}

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
var is_casting = false
var finished_casting = false


#Initializes state, changes animation, etc
func enter():
	equipped_items = owner.inventory.equipped_items
	cycle_equipment()
	
	.enter()


#Cleans up state, reinitializes values like timers
func exit():
	.exit()


#Creates output based on the input event passed in
func handle_input(event):
	.handle_input(event)


#Acts as the _process method would
func update(delta):
	.update(delta)


func on_animation_started(_anim_name):
	return

func on_animation_finished(_anim_name):
	return


func cycle_equipment():
	if equipped_items != null:
		for child in owner.get_node("Rig/Skeleton/Hand_L/Bow_Position").get_children():
			child.queue_free()
		if equipped_items["Bow"]:
			var bow = load(equipped_items["Bow"].item_reference.model_scene).instance()
			owner.get_node("Rig/Skeleton/Hand_L/Bow_Position").add_child(bow)
	
		equipped_bow = equipped_items["Bow"]


###ACTION ANIMS###


#Starts anim and calls function to animate blend amount
func start_anim_1d_action(anim_name, action_blend_pos, fade_time):
	anim_fade_in_1d_action(action_blend_pos, fade_time)
	owner.get_node("AnimationTree").set("parameters/TimeScaleAction/scale", 1.0)
	owner.get_node("AnimationTree").get("parameters/StateMachineAction/playback").start(anim_name)


#Animates blend amount for StateMachineAction
func anim_fade_in_1d_action(action_blend_pos, fade_time):
	var current_blend_pos = owner.get_node("AnimationTree").get("parameters/MovexAction/blend_amount")

	#Check if blend amount is already being animated and interrupt it
	if active_tweens.has("parameters/MovexAction/blend_amount"):
		owner.get_node("Tween").stop(owner.get_node("AnimationTree"), "parameters/MovexAction/blend_amount")
		remove_active_tween("parameters/MovexAction/blend_amount")

	#Start blending fade in if not already doing so
	if current_blend_pos != action_blend_pos and !active_tweens.has("parameters/MovexAction/blend_amount"):
		owner.get_node("Tween").interpolate_property(owner.get_node("AnimationTree"), "parameters/MovexAction/blend_amount", current_blend_pos, action_blend_pos, fade_time, Tween.TRANS_LINEAR)
		owner.get_node("Tween").start()
		add_active_tween("parameters/MovexAction/blend_amount")


func anim_fade_out_1d_action(fade_time):
	var current_blend_pos = owner.get_node("AnimationTree").get("parameters/MovexAction/blend_amount")

	#Check if blend amount is already being animated and interrupt it
	if active_tweens.has("parameters/MovexAction/blend_amount"):
		owner.get_node("Tween").stop_all()
		remove_active_tween("parameters/MovexAction/blend_amount")

	#Set tween values for blend fade out
	owner.get_node("Tween").interpolate_property(owner.get_node("AnimationTree"), "parameters/MovexAction/blend_amount", current_blend_pos, 0.0, fade_time, Tween.TRANS_LINEAR)
	owner.get_node("Tween").start()
	add_active_tween("parameters/MovexAction/blend_amount")


###RIGHT ARM ANIMS###


#Starts anim and calls function to animate blend amount
func start_anim_1d_right_arm(anim_name, right_arm_blend_pos, fade_time):
	anim_fade_in_1d_right_arm(right_arm_blend_pos, fade_time)
	owner.get_node("AnimationTree").get("parameters/StateMachineRightArm/playback").start(anim_name)


#Animates blend amount for StateMachineRightArm
func anim_fade_in_1d_right_arm(right_arm_blend_pos, fade_time):
	var current_blend_pos = owner.get_node("AnimationTree").get("parameters/MovexRightArm/blend_amount")
	
	#Check if blend amount is already being animated and interrupt it
	if active_tweens.has("parameters/MovexRightArm/blend_amount"):
		owner.get_node("Tween").stop(owner.get_node("AnimationTree"), "parameters/MovexRightArm/blend_amount")
		remove_active_tween("parameters/MovexRightArm/blend_amount")
	
	#Start blending fade in if not already doing so
	if current_blend_pos != right_arm_blend_pos and !active_tweens.has("parameters/MovexRightArm/blend_amount"):
		owner.get_node("Tween").interpolate_property(owner.get_node("AnimationTree"), "parameters/MovexRightArm/blend_amount", current_blend_pos, right_arm_blend_pos, fade_time, Tween.TRANS_LINEAR)
		owner.get_node("Tween").start()
		add_active_tween("parameters/MovexRightArm/blend_amount")


func anim_fade_out_1d_right_arm(fade_time):
	var current_blend_pos = owner.get_node("AnimationTree").get("parameters/MovexRightArm/blend_amount")
	
	#Check if blend amount is already being animated and interrupt it
	if active_tweens.has("parameters/MovexRightArm/blend_amount"):
		owner.get_node("Tween").stop_all()
		remove_active_tween("parameters/MovexRightArm/blend_amount")
	
	#Set tween values for blend fade out
	owner.get_node("Tween").interpolate_property(owner.get_node("AnimationTree"), "parameters/MovexRightArm/blend_amount", current_blend_pos, 0.0, fade_time, Tween.TRANS_LINEAR)
	owner.get_node("Tween").start()
	add_active_tween("parameters/MovexRightArm/blend_amount")


func set_initialized_values(init_values_dic):
	for value in init_values_dic:
		init_values_dic[value] = self[value]


func connect_player_signals():
	owner.get_node("AnimationTree").connect("animation_started", self, "on_animation_started")
	owner.get_node("AnimationTree").connect("animation_finished", self, "on_animation_finished")
	owner.connect("focus_target", self, "_on_Player_focus_target_changed")
	owner.connect("inventory_loaded", self, "_on_Player_inventory_loaded")
	owner.get_node("State_Machine_Move").connect("move_state_changed", self, "_on_move_state_changed")
	owner.get_node("State_Machine_Action").connect("initialized_values_dic_set", self, "_on_State_Machine_Action_initialized_values_dic_set")
	owner.get_node("Camera_Rig").connect("focus_direction_changed", self, "_on_Camera_Rig_focus_direction_changed")
	owner.get_node("Attributes/Health").connect("health_depleted", self, "_on_Player_death")
	
	#World Signals
#	owner.connect("entered_area", self, "_on_environment_area_entered")
#	owner.connect("exited_area", self, "_on_environment_area_exited")
	
	#Global Signals
	GameManager.connect("player_respawned", self, "_on_GameManager_player_respawned")
	GameManager.connect("player_voided", self, "_on_GameManager_player_voided")


func disconnect_player_signals():
	owner.get_node("AnimationTree").disconnect("animation_started", self, "on_animation_started")
	owner.get_node("AnimationTree").disconnect("animation_finished", self, "on_animation_finished")
	owner.disconnect("focus_target", self, "_on_Player_focus_target_changed")
	owner.disconnect("inventory_loaded", self, "_on_Player_inventory_loaded")
	owner.get_node("State_Machine_Move").disconnect("move_state_changed", self, "_on_move_state_changed")
	owner.get_node("State_Machine_Action").disconnect("initialized_values_dic_set", self, "_on_State_Machine_Action_initialized_values_dic_set")
	owner.get_node("Camera_Rig").disconnect("focus_direction_changed", self, "_on_Camera_Rig_focus_direction_changed")
	owner.get_node("Attributes/Health").disconnect("health_depleted", self, "_on_Player_death")
	
	#World Signals
#	owner.connect("entered_area", self, "_on_environment_area_entered")
#	owner.connect("exited_area", self, "_on_environment_area_exited")
	
	#Global Signals
	GameManager.disconnect("player_respawned", self, "_on_GameManager_player_respawned")
	GameManager.disconnect("player_voided", self, "_on_GameManager_player_voided")


###PLAYER SIGNAL FUNCTIONS### 

func _on_Player_focus_target_changed(target_pos_node):
	focus_object = target_pos_node


#Equip correct items on character rig once inventory is loaded
func _on_Player_inventory_loaded(inventory_res):
	equipped_items = inventory_res.equipped_items
	cycle_equipment()


func _on_move_state_changed(move_state):
	state_move = move_state
	
	if state_move == "Swim":
		emit_signal("finished", "none")


func _on_State_Machine_Action_initialized_values_dic_set(init_values_dic):
	initialized_values = init_values_dic


func _on_Camera_Rig_focus_direction_changed(direction):
	focus_direction = direction


func _on_Player_death(death):
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


func _on_GameManager_player_respawned():
	can_void = true
	emit_signal("finished", "none")


func _on_GameManager_player_voided():
	if can_void:
		emit_signal("finished", "void")
		can_void = false




