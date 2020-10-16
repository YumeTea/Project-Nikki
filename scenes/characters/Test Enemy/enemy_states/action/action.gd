extends "res://scenes/characters/Test Enemy/enemy_states/interaction/interaction.gd"


#Initialized Values Storage
var initialized_values = {}

#Enemy Flags
var can_void = true

#Enemy Variables
var focus_angle = Vector2()

###Projectile Variables
var projectile
var MAGIC_ORB = preload("res://scenes/characters/Test Enemy/attacks/magic/magic_orb_enemy/magic_orb_enemy.tscn")
var projectile_time = 0
var projectile_count = 0

#Action flags
var is_casting = false
var finished_casting = false


#Initializes state, changes animation, etc
func enter():
	.enter()


#Cleans up state, reinitializes values like timers
func exit():
	.exit()


#Creates output based on the input event passed in
func handle_input(event):
	.handle_input(event)


func handle_ai_input():
	.handle_ai_input()


#Acts as the _process method would
func update(delta):
	.update(delta)


func on_animation_started(_anim_name):
	return

func on_animation_finished(_anim_name):
	return


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


func set_initialized_values(init_values_dic):
	for value in init_values_dic:
		init_values_dic[value] = self[value]


func connect_enemy_signals():
	owner.connect("ai_input_changed", self, "_on_Enemy_ai_input_changed")
	owner.get_node("AnimationTree").connect("animation_started", self, "on_animation_started")
	owner.get_node("AnimationTree").connect("animation_finished", self, "on_animation_finished")
	owner.connect("focus_object_changed", self, "_on_Enemy_focus_object_changed")
	owner.get_node("State_Machine_Move").connect("move_state_changed", self, "_on_move_state_changed")
	owner.get_node("State_Machine_Action").connect("initialized_values_dic_set", self, "_on_State_Machine_Action_initialized_values_dic_set")
	owner.get_node("Camera_Rig").connect("focus_direction_changed", self, "_on_Camera_Rig_focus_direction_changed")
	owner.get_node("Attributes/Health").connect("health_depleted", self, "_on_Enemy_death")
	
	#World Signals
#	owner.connect("entered_area", self, "_on_environment_area_entered")
#	owner.connect("exited_area", self, "_on_environment_area_exited")


func disconnect_enemy_signals():
	owner.disconnect("ai_input_changed", self, "_on_Enemy_ai_input_changed")
	owner.get_node("AnimationTree").disconnect("animation_started", self, "on_animation_started")
	owner.get_node("AnimationTree").disconnect("animation_finished", self, "on_animation_finished")
	owner.disconnect("focus_object_changed", self, "_on_Enemy_focus_object_changed")
	owner.get_node("State_Machine_Move").disconnect("move_state_changed", self, "_on_move_state_changed")
	owner.get_node("State_Machine_Action").disconnect("initialized_values_dic_set", self, "_on_State_Machine_Action_initialized_values_dic_set")
	owner.get_node("Camera_Rig").disconnect("focus_direction_changed", self, "_on_Camera_Rig_focus_direction_changed")
	owner.get_node("Attributes/Health").disconnect("health_depleted", self, "_on_Enemy_death")
	
	#World Signals
#	owner.connect("entered_area", self, "_on_environment_area_entered")
#	owner.connect("exited_area", self, "_on_environment_area_exited")


###Enemy SIGNAL FUNCTIONS### 


func _on_Enemy_ai_input_changed(input_dict):
	input = input_dict


func _on_Enemy_focus_object_changed(target):
	if target:
		focus_object = target
	else:
		focus_object = null


func _on_move_state_changed(move_state):
	state_move = move_state
	print(state_move)


func _on_State_Machine_Action_initialized_values_dic_set(init_values_dic):
	initialized_values = init_values_dic


func _on_Camera_Rig_focus_direction_changed(direction):
	focus_direction = direction


func _on_Enemy_death(death):
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

