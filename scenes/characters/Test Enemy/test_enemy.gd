extends "res://scenes/characters/character scene/character.gd"


signal ai_input_changed(input_dic)


var input_current = {
	"left_stick": Vector2(0,0),
	"right_stick": Vector2(0,0),
	"action_y": null,
	"action_l1": null,
	"action_l2": null,
}

var input_previous = {
	"left_stick": Vector2(0,0),
	"right_stick": Vector2(0,0),
	"action_y": null,
	"action_l1": null,
	"action_l2": null,
}

var input = {
	"input_current": input_current,
	"input_previous": input_previous,
}

var seek_target_name = "Player"


func _ready():
	emit_signal("ai_input_changed", input)


func _ai_input(_input):
	if is_ai_action_just_pressed("lock_target", input):
		lock_target()


func _physics_process(_delta):
	#Clear AI input at start
	clear_ai_input()
	
	#Get AI inputs
	get_move_direction()
	get_look_direction()
	get_action_input()
	emit_signal("ai_input_changed", input)
	
	#Process AI input
	_ai_input(input)
	
	check_targets_visibility()
	if targetting:
		if main_target == null:
			targetting = false
		emit_signal("focus_target", main_target)


func get_move_direction():
#	if targetting:
#		press_ai_input("left_stick", Vector2(0,1))
#	else:
	press_ai_input("left_stick", Vector2(0,0))


func get_look_direction():
	if !targetting:
		press_ai_input("right_stick", Vector2(sin(OS.get_time()["second"]/2), 0))


func get_action_input():
	if !targetting:
		seek_target(seek_target_name)
	else:
		press_ai_input("action_l2", "center_view")
		press_ai_input("action_y", "cast")


func seek_target(target_name):
	for actor in visible_targets:
		if actor.get_name() == target_name and !targetting:
			press_ai_input("action_l1", "lock_target")


func lock_target():
	if !targetting:
		main_target = get_main_target(visible_targets)
		targetting = true
		emit_signal("focus_target", main_target)
	else:
		main_target = null
		targetting = false
		emit_signal("focus_target", main_target)


func get_main_target(target_array): #if array is empty, returns null
	var centering = 0 #stores how close target is to center camera view
	var target_main
	for target in target_array:
		var target_direction = head_position.direction_to(target.get_global_transform().origin)
		if centering < focus_direction.dot(target_direction):
			centering = focus_direction.dot(target_direction)
			target_main = target
	return target_main


func clear_ai_input():
	for input_name in input["input_current"]:
		input["input_previous"][input_name] = input["input_current"][input_name]
	
	for input_name in input["input_current"]:
		var input_value = input["input_current"][input_name]
		match typeof(input_value):
			TYPE_STRING:
				input["input_current"][input_name] = null
			TYPE_VECTOR2:
				input["input_current"][input_name] = Vector2(0,0)


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


func hit_effect(_effect_type):
	return


func _on_Health_health_depleted(_health_depleted):
	set_physics_process(false)
	$AnimationPlayer.play("Perish")


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Perish":
		queue_free()

