extends KinematicBody

"""
Update target reticle scene when AnimatedSprite3D is fixed
"""

signal position_changed(current_position)
signal velocity_changed(current_velocity)
signal facing_angle_changed(facing_angle)
signal is_falling(is_falling)
signal targets_changed(visible_targets)
signal focus_target(target_pos_node)

#State Machine Signals
signal entered_new_view(view_mode)
signal inventory_loaded(inventory)

#Scene Change Signals
signal entered_area(area_type, surface_height)
signal exited_area(area_type)

#Save Data Variables
onready var DATA_PATH = "res://data/temp/player_data.tres"
var saved_values = {
	"inventory": null,
	"health": 0.0,
	"view_mode": null
}

#Scene Storage
var target_reticle = preload("res://scenes/objects/Test Objects/3D Sprites/Target Reticle/Target_Reticle_Temp/Target_Reticle_Temp.tscn")
export (String, FILE) var player_scene

#Node Storage
onready var health_node = $Attributes/Health

#World Interaction Variables
var max_fall_height = 34 #should be replaced by max_fall_velocity
var base_fall_damage = 16
var fall_height = 0
var land_height = 0
var is_falling = false

#Player Variables
var player_position

#Targetting Variables
var targettable_objects = []
var visible_targets = []
var camera_position
var camera_direction #where camera would be if attached to player camera rig
var target_position
var target_direction
var min_cam_target_dotp = 0.65 #angle = 90 - (90 * max_cam_target_dotp)
var main_target
var targetting = false

#Inventory Variables
const inventory_resource = preload("res://scripts/custom_resources/inventory_resource.gd")
var inventory = inventory_resource.new()


func _ready():
	#Connect to player state machine signals
	for child in $State_Machine_Move.get_children():
		child.connect("position_changed", self, "_on_position_changed")
	for child in $State_Machine_Move.get_children():
		child.connect("velocity_changed", self, "_on_velocity_changed")
	for child in $State_Machine_Move.get_children():
		child.connect("started_falling", self, "_on_started_falling")
	for child in $State_Machine_Move.get_children():
		child.connect("landed", self, "_on_landing")
	for child in $State_Machine_Move.get_children():
		child.connect("lock_target", self, "_on_lock_target")
	for child in $Camera_Rig/State_Machine.get_children():
		child.connect("entered_new_view", self, "_on_Camera_State_Machine_entered_new_view")
	
	#Set cast glow invisible(should think of another way to do this at start)
	$Rig/Projectile_Position/cast_glow.visible = false
	
	#Send initial values for signal recievers
	emit_signal("facing_angle_changed", $Rig.get_global_transform().basis.get_euler())
	emit_signal("targets_changed", visible_targets)
	emit_signal("focus_target", main_target)


func _input(event):
	if event.is_action_pressed("lock_target") and event.get_device() == 0:
		lock_target()


func _physics_process(_delta):
	emit_signal("facing_angle_changed", $Rig.get_global_transform().basis.get_euler())
	check_targets_visibility()
	if targetting:
		if main_target == null:
			targetting = false
		emit_signal("focus_target", main_target)
	highlight_target_reticle(main_target, targetting)


func take_damage(value):
	health_node.take_damage(value)


func fall_damage():
	var distance_fallen = fall_height - land_height
	var fall_damage = pow(base_fall_damage, (((distance_fallen/max_fall_height)/2.0) + 0.5))
	return fall_damage


#Uses camera position and camera direction to determine if a target is visible and 
#viable to target
func check_targets_visibility():
	for target in targettable_objects:
		target_position = target.get_global_transform().origin
		target_direction = camera_position.direction_to(target_position)
		var camera_dotp_target = camera_direction.dot(target_direction)
		
		#Check if target is inside character's "view cone"
		if camera_dotp_target > min_cam_target_dotp: #if target is in view cone
			var obstruction = raycast_query(camera_position, target_position, target)
			if obstruction.empty(): #if raycast query didn't hit anything
				if target in visible_targets:
					pass
				else:
					visible_targets.push_front(target)
					draw_target_reticle(target)
					emit_signal("targets_changed", visible_targets)
			else:
				if target == main_target: #if camera line of sight to target blocked, stop targetting
					targetting = false
					main_target = null
					emit_signal("focus_target", main_target)
				visible_targets.erase(target)
				erase_target_reticle(target)
				emit_signal("targets_changed", visible_targets)
		else:
			if target == main_target:
				var obstruction = raycast_query(camera_position, target_position, target)
				if obstruction:
					if target == main_target:
						targetting = false
						main_target = null
						emit_signal("focus_target", main_target)
			else:
				erase_target_reticle(target)
			visible_targets.erase(target)
			emit_signal("targets_changed", visible_targets)


func raycast_query(from, to, exclude):
	var space_state = get_world().direct_space_state
	var result = space_state.intersect_ray(from, to, [self, exclude])
	return result


func get_main_target(target_array): #if array is empty, returns null
	var centering = 0 #stores how close target is to center camera view
	var target_main
	for target in target_array:
		var target_direction = camera_position.direction_to(target.get_global_transform().origin)
		if centering < camera_direction.dot(target_direction):
			centering = camera_direction.dot(target_direction)
			target_main = target
	return target_main


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
	highlight_target_reticle(focus_target, targetting)


func draw_target_reticle(target):
	var reticle = target_reticle.instance()
	if target.has_node("Reticle"):
		return
	else:
		target.add_child(reticle)
		reticle.draw(target)


func erase_target_reticle(target):
	if target:
		for child in target.get_children():
			var child_name = child.get_name()
			if child_name == "Reticle":
				target.get_node("Reticle").queue_free()


func highlight_target_reticle(focus_target, is_targetting):
	if focus_target:
		if focus_target.has_node("Reticle"):
			var reticle = focus_target.get_node("Reticle")
			if is_targetting:
				reticle.set_frame(1)
			else:
				reticle.set_frame(0)


func hit_effect(_effect_type):
	return


func save_data(save_file : Resource):
	saved_values["inventory"] = inventory
	saved_values["health"] = $Attributes/Health.health
	saved_values["view_mode"] = $Camera_Rig/State_Machine.current_state.view_mode
	
	save_file.data[DATA_PATH] = saved_values


func load_data(save_game : Resource):
	saved_values = save_game.data[DATA_PATH]
	
	inventory = saved_values["inventory"]
	$Attributes/Health.set_health(saved_values["health"])
	for child in $Camera_Rig/State_Machine.get_children():
		child.set_view_mode(saved_values["view_mode"])
	
	emit_signal("inventory_loaded", inventory)


func _on_position_changed(position):
	player_position = position
	emit_signal("position_changed", position)


func _on_velocity_changed(velocity):
	var current_velocity = velocity
	emit_signal("velocity_changed", current_velocity)

func _on_started_falling(height):
	if is_falling == false:
		fall_height = height
		is_falling = true
		
		emit_signal("is_falling", is_falling)


func _on_landing(height):
	if is_falling == true:
		land_height = height
		var height_difference = fall_height - land_height
		if height_difference > max_fall_height:
			take_damage(fall_damage())
		is_falling = false
		
		emit_signal("is_falling", is_falling)


func _entered_area(area_type, surface_height):
	emit_signal("entered_area", area_type, surface_height)


func _exited_area(area_type):
	emit_signal("exited_area", area_type)


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
		erase_target_reticle(body)
		emit_signal("targets_changed", visible_targets)


func _on_Camera_State_Machine_entered_new_view(view_mode):
	if view_mode == "first_person":
		$Rig/Skeleton/Head.set_layer_mask_bit(0, false)
		$Rig/Skeleton/Head.set_layer_mask_bit(20, true)
		emit_signal("entered_new_view", view_mode)
	if view_mode == "third_person":
		$Rig/Skeleton/Head.set_layer_mask_bit(0, true)
		$Rig/Skeleton/Head.set_layer_mask_bit(20, false)
		emit_signal("entered_new_view", view_mode)


func _on_Camera_Rig_camera_direction_changed(direction):
	camera_direction = direction


func _on_Camera_Rig_camera_moved(camera_transform):
	camera_position = camera_transform.origin


func _on_Camera_Rig_break_target():
	lock_target()


