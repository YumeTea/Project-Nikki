extends "res://scenes/characters/character scene/character.gd"


signal ai_input_changed(input_dic)


#Input
var input = {}

#Pathfinding
export var assigned_route : String


func _ready():
	for node in $State_Machine_AI.get_children():
		node.connect("ai_input_changed", self, "_on_State_Machine_AI_input_changed")
	for node in $State_Machine_AI.get_children():
		node.connect("focus_object_changed", self, "_on_State_Machine_AI_focus_object_changed")


func _input(event):
	return


func hit_effect(_effect_type):
	return


###UTILITY FUNCTIONS###


func calculate_global_y_rotation(direction):
	var test_direction = Vector2(0,1)
	var direction_to = Vector2(direction.x, direction.z)
	var y_rotation = -test_direction.angle_to(direction_to)
	return y_rotation #Output is PI > y > -PI


###AI INPUT FUNCTIONS###


func press_ai_input(input_name, value):
	input["input_current"][input_name] = value


func is_ai_action_pressed(action, input_dic):
	for input_name in input_dic["input_current"]:
		if typeof(input_dic["input_current"][input_name]) == typeof(action):
			if input_dic["input_current"][input_name] == action:
					return true
	
	return false


func is_ai_action_released(action, input_dic):
	for input_name in input_dic["input_previous"]:
		if typeof(input_dic["input_previous"][input_name]) == typeof(action):
			if input_dic["input_previous"][input_name] == action:
				if input["input_previous"][input_name] != input["input_current"][input_name]:
					return true
	
	return false


func is_ai_action_just_pressed(action, input_dic):
	for input_name in input_dic["input_current"]:
		if typeof(input_dic["input_current"][input_name]) == typeof(action):
			if input["input_current"][input_name] == action:
				if input["input_current"][input_name] == input["input_previous"][input_name]:
					return true
	
	return false


###SIGNAL FUNCTIONS###


func _on_State_Machine_AI_input_changed(input_dic):
	emit_signal("ai_input_changed", input_dic)


func _on_State_Machine_AI_focus_object_changed(focus_object):
#	print(focus_object)
	emit_signal("focus_object_changed", focus_object)


func _on_Health_health_depleted(_health_depleted):
	set_physics_process(false)
	$AnimationPlayer.play("Perish")


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Perish":
		queue_free()

