extends "res://scenes/characters/Test Enemy/enemy_states/interaction/interaction.gd"


"""
AI sometimes centers on target, but does not cast
"""


signal ai_input_changed(input_dic)
signal focus_object_changed(focus_object)


#Node Storage
onready var Navigator = owner.get_parent().get_parent().get_node("Navigation")
onready var Routes = owner.get_parent().get_parent().get_node("Navigation/Routes")
onready var Timer_Route = owner.get_node("State_Machine_AI/Timer_Route")

#Initialized Values Storage
var initialized_values = {}

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

#Targetting Variables
var targettable_objects = []
var visible_targets = []
var closest_target = null
var head_position
var target_position
var target_direction
var min_cam_dot_target = 0.65 #angle = 90 - (90 * max_cam_target_dotp)

#Seeking Variables
var seek_target_name = "Player"
var seek_target_pos_last : Vector3

#Pathfinding Variables
var path : Array =  []
var path_point : int = 0
var route : Array = []
var advancing = false

#AI Flags
var spotted_seek_target : bool = false


#Initializes state, changes animation, etc
func enter():
	input = {
	"input_current": input_current,
	"input_previous": input_previous,
	}


#Cleans up state, reinitializes values like timers
func exit():
	return


#Creates output based on player input
func handle_input(event):
	if event.is_action_pressed("debug_input") and event.get_device() == 0:
		Timer_Route.stop()
		route = route_advance(route)


func handle_ai_input():
	if is_ai_action_just_pressed("lock_target", input) and !targetting:
		lock_target()


#Acts as the _process method would
func update(_delta):
	#Visible targets update
	check_targets_visibility()


func _on_animation_finished(_anim_name):
	return


###AI INPUT FUNCTIONS###


#Manupulates look input to look at target point, accounting for look_speed of head rig
func look_to_point(target_point):
	var direction
	
	###Calc look direction while going to player position
	var target_direction = Enemy.global_transform.origin.direction_to(target_point)
	target_direction.y = 0.0
	target_direction = target_direction.normalized()
	
	var angle_to_target = calculate_global_y_rotation(target_direction) - calculate_global_y_rotation(focus_direction)
	angle_to_target = bound_angle(angle_to_target)
	
	
	if angle_to_target > 0.0:
		if angle_to_target >= deg2rad(Camera_Rig.look_speed):
			direction = Vector2(-1, 0)
		else:
			direction = Vector2((-rad2deg(angle_to_target)) / (Camera_Rig.look_speed), 0)
	elif angle_to_target < 0.0:
		if angle_to_target <= deg2rad(-Camera_Rig.look_speed):
			direction = Vector2(1, 0)
		else:
			direction = Vector2((-rad2deg(angle_to_target)) / (Camera_Rig.look_speed), 0)
	else:
		direction = Vector2(0, 0)
	
	return direction


#Handles flag for whether seek target is found
func seek_target(target_name):
	if !targetting:
		for actor in visible_targets:
			if actor.name == target_name:
#				seek_target_pos_last = actor.global_transform.origin
#				spotted_seek_target = true
				return
	
	spotted_seek_target = false


#Moves current inputs to previous input dict and clears input_current
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


#Returns true if action is in input_current but not in input_previous
func is_ai_action_just_pressed(action, input_dic):
	for input_name in input_dic["input_current"]:
		if typeof(input_dic["input_current"][input_name]) == typeof(action):
			if input["input_current"][input_name] == action:
				if input["input_current"][input_name] != input["input_previous"][input_name]:
					return true
				else:
					return false
	
	return false


###TARGETTING FUNCTIONS###


#Determines if objects are in view cone and puts those objects in visible_targets; updates centermost object
func check_targets_visibility():
	var closest_target_new = null
	var closest_cam_dot_target = -1.0
	
	for target in targettable_objects:
		target_position = target.get_node("Target_Pos").get_global_transform().origin
		target_direction = head_position.direction_to(target_position)
		var cam_dot_target = focus_direction.dot(target_direction)
		
		#Check if target is inside character's "view cone"
		#Determine target closest to view center
		if cam_dot_target > min_cam_dot_target: #if target is in view cone
			var obstruction = raycast_query(head_position, target_position, target)
			if obstruction.empty(): #if raycast query didn't hit anything
				#If target is closer to center than current closest, replace current closest target
				if cam_dot_target > closest_cam_dot_target:
					closest_target_new = target
					closest_cam_dot_target = cam_dot_target
				
				if target in visible_targets:
					continue
				else:
					visible_targets.push_front(target)
			else:
				visible_targets.erase(target)
				if target == focus_object:
					lock_target()
		else:
			visible_targets.erase(target)
			if target == focus_object:
				lock_target()
	
	#Update closest target
	closest_target = closest_target_new
	
	#
	for object in targettable_objects:
		if object in visible_targets:
			pass
		else:
			if object == focus_object:
				lock_target()


func raycast_query(from, to, exclude):
	var space_state = Enemy.get_world().direct_space_state
	var result = space_state.intersect_ray(from, to, [owner, exclude])
	return result


func lock_target():
	if !targetting and closest_target != null:
		focus_object = closest_target
		targetting = true
	else:
		focus_object = null
		targetting = false
		spotted_seek_target = false
	emit_signal("focus_object_changed", focus_object)


###PATHFINDING FUNCTIONS###


#Tells navigation node to calculate path to input target node
func move_to(target_node):
	path = Navigator.get_simple_path(Enemy.global_transform.origin, target_node.global_transform.origin)
	path_point = 0
	advancing = true


#Advances path point along path set up in move_to
func calc_target_path():
	var target_direction
	var direction
	
	if path_point < path.size():
		target_direction = (path[path_point] - Enemy.global_transform.origin)
		target_direction = Vector2(target_direction.x, target_direction.z)
		#Calc path to next point if within 1 unit of current point
		if target_direction.length() < 1.0:
			path_point += 1
			if (path_point + 1 < path.size()):
				target_direction = (path[path_point] - Enemy.global_transform.origin)
				target_direction = Vector2(target_direction.x, target_direction.z)
			else:
				direction = Vector2(0,0)
				advancing = false
		
		var move_angle
		
		move_angle = calculate_global_y_rotation(focus_direction) - calculate_global_y_rotation(Vector3(target_direction.x, 0.0, target_direction.y))
		
		direction = Vector2(0.0, target_direction.length()).rotated(move_angle)
		direction = direction.normalized()
		
		###DEBUG###
		if path_point < path.size():
			owner.get_node("Debug/Path_Point").global_transform.origin = path[path_point]
	else:
		direction = Vector2(0,0)
		advancing = false
		
		if Timer_Route.is_stopped():
			Timer_Route.start(7.0)
	
	
	return direction


#Populates route array with route_name's waypoints
func route_assign(route_name):
	route = []
	
	if route_name:
		if route_name != "":
			for waypoint in Routes.get_node(route_name).get_children():
				route.append(waypoint)
	
	move_to(route[0])


#Advances route to next waypoint
func route_advance(route_array):
	route_array.append(route_array[0])
	route_array.remove(0)
	move_to(route_array[0])
	
	return route_array


###UTILITY FUNCTIONS###


func calculate_global_y_rotation(direction):
	var test_direction = Vector2(0,1)
	var direction_to = Vector2(direction.x, direction.z)
	var y_rotation = -test_direction.angle_to(direction_to)
	return y_rotation #Output is PI > y > -PI


func set_initialized_values(init_values_dic):
	for value in init_values_dic:
		init_values_dic[value] = self[value]


###SIGNAL CONNECTIONS###


func connect_enemy_signals():
	owner.get_node("State_Machine_AI").connect("initialized_values_dic_set", self, "_on_State_Machine_AI_initialized_values_dic_set")
	owner.get_node("Camera_Rig").connect("head_moved", self, "_on_Camera_Rig_head_moved")
	owner.get_node("Camera_Rig").connect("focus_direction_changed", self, "_on_Camera_Rig_focus_direction_changed")
	owner.get_node("Camera_Rig").connect("break_target", self, "_on_Camera_Rig_break_target")
	owner.get_node("Targetting_Area").connect("body_entered", self, "_on_Targetting_Area_body_entered")
	owner.get_node("Targetting_Area").connect("body_exited", self, "_on_Targetting_Area_body_exited")
	owner.get_node("State_Machine_AI/Timer_Route").connect("timeout", self, "_on_Timer_Route_timeout")


func disconnect_enemy_signals():
	owner.get_node("State_Machine_AI").disconnect("initialized_values_dic_set", self, "_on_State_Machine_AI_initialized_values_dic_set")
	owner.get_node("Camera_Rig").disconnect("head_moved", self, "_on_Camera_Rig_head_moved")
	owner.get_node("Camera_Rig").disconnect("focus_direction_changed", self, "_on_Camera_Rig_focus_direction_changed")
	owner.get_node("Camera_Rig").disconnect("break_target", self, "_on_Camera_Rig_break_target")
	owner.get_node("Targetting_Area").disconnect("body_entered", self, "_on_Targetting_Area_body_entered")
	owner.get_node("Targetting_Area").disconnect("body_exited", self, "_on_Targetting_Area_body_exited")
	owner.get_node("State_Machine_AI/Timer_Route").disconnect("timeout", self, "_on_Timer_Route_timeout")


###SIGNAL FUNCTIONS###


func _on_State_Machine_AI_initialized_values_dic_set(init_values_dic):
	initialized_values = init_values_dic


func _on_Camera_Rig_head_moved(head_transform):
	head_position = head_transform.origin


func _on_Camera_Rig_focus_direction_changed(direction):
	focus_direction = direction


func _on_Camera_Rig_break_target():
	if targetting:
		lock_target()


func _on_Targetting_Area_body_entered(body):
	if body in get_tree().get_nodes_in_group("targettable"):
		targettable_objects.push_front(body)


func _on_Targetting_Area_body_exited(body):
	if body in get_tree().get_nodes_in_group("targettable"):
		if body == focus_object:
			focus_object = null
			targetting = false
			emit_signal("focus_object_changed", focus_object)
		targettable_objects.erase(body)
		visible_targets.erase(body)



