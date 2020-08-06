extends "res://scenes/characters/character scene/character.gd"

signal ai_input_changed(input_dic)

var input = {
	"left_stick": Vector2(),
	"right_stick": Vector2(),
	"action_y": null,
	"action_l1": null,
	"action_l2": null,
}

var seek_target_name = "Player"

func _ready():
	emit_signal("ai_input_changed", input)


func _physics_process(delta):
	#Get AI inputs
	get_move_direction()
	get_look_direction()
	get_action_input()
	emit_signal("ai_input_changed", input)
	check_targets_visibility()
	if targetting:
		if main_target == null:
			targetting = false
		emit_signal("focus_target", main_target)
	clear_ai_input()

func get_move_direction():
	input["left_stick"] = Vector2(0,1)


func get_look_direction():
	input["right_stick"] = Vector2(1,0)


func get_action_input():
	if !targetting:
		seek_target(seek_target_name)
	else:
		center_on_target()
		input["action_y"] = "cast"


func clear_ai_input():
	for value in input:
		input[value] = null



func seek_target(target_name):
	for actor in visible_targets:
		if actor.get_name() == target_name and !targetting:
			lock_target()
			input["action_l1"] = "lock_target"
	if main_target == null:
		targetting = false


func center_on_target():
	if main_target.get_name() == seek_target_name:
		input["action_l2"] = "center_view"


func lock_target():
	var focus_target = main_target
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
		if centering < facing_direction.dot(target_direction):
			centering = facing_direction.dot(target_direction)
			target_main = target
	return target_main


func is_ai_action_pressed(action, input_dic):
	for input_name in input_dic:
		if typeof(input_dic[input_name]) == typeof(action):
			if input[input_name] == action:
				return true
	
	return false




