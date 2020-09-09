extends KinematicBody


signal focus_target(target_pos_node)

#Node Storage
onready var health_node = $Attributes/Health

#World Interaction Variables
var max_fall_height = 34
var base_fall_damage = 16
var fall_height = 0
var land_height = 0
var is_falling = false

#Character Variables
var player_position

#Targetting Variables
var targettable_objects = []
var visible_targets = []
var head_position
var focus_direction
var facing_direction
var target_position
var target_direction
var min_head_target_dotp = 0.65 #angle = 90 - (90 * max_cam_target_dotp)
var main_target

#Character Flags
var targetting = false
var death = false


func _ready():
	for child in $State_Machine.get_children():
		child.connect("position_changed", self, "_on_position_changed")
	for child in $State_Machine.get_children():
		child.connect("started_falling", self, "_on_started_falling")
	for child in $State_Machine.get_children():
		child.connect("landed", self, "_on_landing")
	for child in $State_Machine.get_children():
		child.connect("lock_target", self, "_on_lock_target")


func take_damage(value):
	if !death:
		$AnimationPlayer.play("Damaged")
		health_node.take_damage(value)


func fall_damage():
	var distance_fallen = fall_height - land_height
	var fall_damage = pow(base_fall_damage, (((distance_fallen/max_fall_height)/2.0) + 0.5))
	return fall_damage


###Move down a level from this script for npc's
func check_targets_visibility():
	for target in targettable_objects:
		target_position = target.get_global_transform().origin
		target_direction = head_position.direction_to(target_position)
		var head_dotp_target = focus_direction.dot(target_direction)
		
		#Check if target is inside character's "view cone"
		if head_dotp_target > min_head_target_dotp: #if target is in view cone
			var obstruction = raycast_query(head_position, target_position, target)
			if obstruction.empty(): #if raycast query didn't hit anything
				if target in visible_targets:
					pass
				else:
					visible_targets.push_front(target)
			else:
				if target == main_target: #if camera line of sight to target blocked, stop targetting
					targetting = false
					main_target = null
					emit_signal("focus_target", main_target)
				visible_targets.erase(target)
		else:
			if target == main_target:
				var obstruction = raycast_query(head_position, target_position, target)
				if obstruction:
					if target == main_target:
						targetting = false
						main_target = null
						emit_signal("focus_target", main_target)
			visible_targets.erase(target)


func raycast_query(from, to, exclude):
	var space_state = get_world().direct_space_state
	var result = space_state.intersect_ray(from, to, [self, exclude])
	return result


func get_main_target(target_array): #if array is empty, returns null
	var centering = 0 #stores how close target is to center camera view
	var target_main
	for target in target_array:
		var target_direction = head_position.direction_to(target.get_global_transform().origin)
		if centering < focus_direction.dot(target_direction):
			centering = focus_direction.dot(target_direction)
			target_main = target
	return target_main


func lock_target():
	if !targetting:
		main_target = get_main_target(visible_targets)
		targetting = true
	else:
		main_target = null
		targetting = false


func _on_position_changed(position):
	player_position = position


func _on_started_falling(height):
	if is_falling == false:
		fall_height = height
		is_falling = true


func _on_landing(height):
	if is_falling == true:
		land_height = height
		var height_difference = fall_height - land_height
		if height_difference > max_fall_height:
			health_node.take_damage(fall_damage())
		is_falling = false


func _on_Targetting_Area_body_entered(body):
	if body in get_tree().get_nodes_in_group("targettable"):
		targettable_objects.push_front(body)


func _on_Targetting_Area_body_exited(body):
	if body in get_tree().get_nodes_in_group("targettable"):
		if body == main_target:
			main_target = null
			targetting = false
			emit_signal("focus_target", main_target)
		targettable_objects.erase(body)
		visible_targets.erase(body)


func _on_Camera_Rig_break_target():
	lock_target()


func _on_Camera_Rig_head_moved(head_transform):
	head_position = head_transform.origin


func _on_Camera_Rig_focus_direction_changed(direction):
	focus_direction = direction

