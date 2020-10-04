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

#Seeking Variables
var seeking = false
var seek_target_name = "Player"

#Pathfinding Variables
var path = []
var path_point = 0

onready var nav = get_parent().get_parent().get_node("Navigation")


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


func hit_effect(_effect_type):
	return


func seek_target(target_name):
	for actor in visible_targets:
		if actor.get_name() == target_name and !targetting:
			press_ai_input("action_l1", "lock_target")


func lock_target():
	var focus_target = main_target
	
	if !targetting:
		main_target = closest_target
		targetting = true
	else:
		main_target = null
		targetting = false
	emit_signal("focus_target", main_target)


func calc_target_path():
	var target_direction
	var direction
	
	if path_point < path.size():
		target_direction = (path[path_point] - global_transform.origin)
		target_direction = Vector2(target_direction.x, target_direction.z)
		#Calc path to next point if within 1 unit of current point
		if target_direction.length() < 1.0:
			path_point += 1
			if (path_point + 1 < path.size()):
				target_direction = (path[path_point] - global_transform.origin)
				target_direction = Vector2(target_direction.x, target_direction.z)
			else:
				direction = Vector2(0,0)
				seeking = false
		
		var move_angle
		
		move_angle = calculate_global_y_rotation(focus_direction) - calculate_global_y_rotation(Vector3(target_direction.x, 0.0, target_direction.y))
		
		direction = Vector2(0.0, target_direction.length()).rotated(move_angle)
		direction = direction.normalized()
		
		###DEBUG###
		if path_point < path.size():
			$Debug/Path_Point.global_transform.origin = path[path_point]
	else:
		direction = Vector2(0,0)
		seeking = false
	
	
	return direction


func move_to(target_node):
	path = nav.get_simple_path(global_transform.origin, target_node.global_transform.origin)
	path_point = 0


###UTILITY FUNCTIONS###


func calculate_global_y_rotation(direction):
	var test_direction = Vector2(0,1)
	var direction_to = Vector2(direction.x, direction.z)
	var y_rotation = -test_direction.angle_to(direction_to)
	return y_rotation #Output is PI > y > -PI


###AI INPUT FUNCTIONS###


func get_move_direction():
	var direction = calc_target_path()
	press_ai_input("left_stick", direction)


func get_look_direction():
	var direction
	
	if !targetting and !seeking:
		direction = Vector2(sin(OS.get_time()["second"]/2), 0)
	else:
		###Calc look direction while going to player position
		var target_direction = global_transform.origin.direction_to(Global.get_Player().global_transform.origin)
		target_direction.y = 0.0
		target_direction = target_direction.normalized()
		
		var angle_to_target = calculate_global_y_rotation(target_direction) - calculate_global_y_rotation(focus_direction)
		
		if angle_to_target > 0.0:
			direction = Vector2(-1, 0)
		elif angle_to_target < 0.0:
			direction = Vector2(1, 0)
		else:
			direction = Vector2(0, 0)
		
	press_ai_input("right_stick", direction)


func get_action_input():
	if !targetting:
		seek_target(seek_target_name)
	else:
#		press_ai_input("action_l2", "center_view")
		press_ai_input("action_y", "cast")


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


###SIGNAL FUNCTIONS###


func _on_Health_health_depleted(_health_depleted):
	set_physics_process(false)
	$AnimationPlayer.play("Perish")


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Perish":
		queue_free()


func _on_Timer_timeout():
	if Global.get_Player() and nav:
		move_to(Global.get_Player())
		seeking = true
