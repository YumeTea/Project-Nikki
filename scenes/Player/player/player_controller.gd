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

#Input Variables
var input_move_direction : Vector3

#Player Variables
var player_position : Vector3

#Targetting Variables
var targettable_objects = []
var visible_targets = []
var closest_target = null
var main_target = null
var camera_position
var camera_direction #where camera would be if attached to player camera rig
var target_position
var target_direction
var min_cam_dot_target = 0.65 #angle = 90 - (90 * max_cam_target_dotp)
var targetting = false

#Interactables Variables
var nearby_interactables = []
var closest_interactable = null
var min_cam_dot_interactable = 0.6

#Inventory Variables
const inventory_resource = preload("res://scripts/custom_resources/inventory_resource.gd")
var inventory = inventory_resource.new()


func _ready():
	#Connect to player state machine signals
	for child in $State_Machine_Move.get_children():
		child.connect("input_move_direction_changed", self, "_on_input_move_direction_changed_changed")
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
	if event.is_action_pressed("interact") and event.get_device() == 0:
		if closest_interactable:
			closest_interactable.interact()
			
#	if event.is_action_pressed("debug_input") and event.get_device() == 0:
#		print(closest_interactable)


func _physics_process(_delta):
	emit_signal("facing_angle_changed", $Rig.global_transform.basis.get_euler())
	check_interactables_visibility()
	check_targets_visibility()


func take_damage(value):
	health_node.take_damage(value)


func fall_damage():
	var distance_fallen = fall_height - land_height
	var fall_damage = pow(base_fall_damage, (((distance_fallen/max_fall_height)/2.0) + 0.5))
	return fall_damage


func hit_effect(_effect_type):
	return


#Uses camera position and camera direction to determine if a target is visible and 
#viable to target
func check_targets_visibility():
	var closest_target_new = null
	var closest_cam_dot_target = -1.0
	
	for target in targettable_objects:
		target_position = target.get_global_transform().origin
		target_direction = camera_position.direction_to(target_position)
		var cam_dot_target = camera_direction.dot(target_direction)
		
		#Check if target is inside character's "view cone"
		#Determine target closest to view center
		if cam_dot_target > min_cam_dot_target: #if target is in view cone
			var obstruction = raycast_query(camera_position, target_position, target)
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
		else:
			visible_targets.erase(target)
	
	#Update closest target
	closest_target = closest_target_new
	
	#Draw target reticles
	for target in targettable_objects:
		if target in visible_targets:
			draw_target_reticle(target)
		else:
			erase_target_reticle(target)
			if target == main_target:
				targetting = false
				main_target = null
				emit_signal("focus_target", main_target)
	
	emit_signal("targets_changed", visible_targets)


func lock_target():
	var focus_target = main_target
	
	if !targetting:
		main_target = closest_target
		targetting = true
		highlight_target_reticle(main_target, targetting)
	else:
		main_target = null
		targetting = false
		highlight_target_reticle(focus_target, targetting)
	emit_signal("focus_target", main_target)


func draw_target_reticle(target):
	var reticle = target_reticle.instance()
	if target.has_node("Reticle"):
		return
	else:
		target.add_child(reticle)
		reticle.draw(target)


func erase_target_reticle(target):
	if target:
		if target.has_node("Reticle"):
			target.get_node("Reticle").queue_free()


func highlight_target_reticle(focus_target, is_targetting):
	if focus_target:
		if focus_target.has_node("Reticle"):
			var reticle = focus_target.get_node("Reticle")
			if is_targetting:
				reticle.set_frame(1)
			else:
				reticle.set_frame(0)


func check_interactables_visibility():
	var closest_interactable_new = null
	var interactable_position
	var interactable_direction
	var closest_cam_dot_interactable = -1.0
	
	###Determine closest interactable object
	for interactable in nearby_interactables:
		interactable_position = interactable.global_transform.origin
		interactable_direction = camera_position.direction_to(interactable_position)
		var camera_dot_interactable = camera_direction.dot(interactable_direction)
		
		#Check if target is inside character's "view cone"
		if camera_dot_interactable > min_cam_dot_interactable: #if target is in view cone
			var obstruction = raycast_query(camera_position, interactable_position, interactable)
			if obstruction.empty(): #if raycast query didn't hit anything
				if camera_dot_interactable > closest_cam_dot_interactable:
					closest_cam_dot_interactable = camera_dot_interactable
					closest_interactable_new = interactable
			else:
				if interactable == closest_interactable: #if camera line of sight to target blocked, stop targetting
					closest_interactable_new = null
	
	###Unhighlight previous interactable and highlight new one if they are not null
	if closest_interactable:
		highlight_interactable(closest_interactable, false)
	
	closest_interactable = closest_interactable_new
	
	if closest_interactable:
		highlight_interactable(closest_interactable, true)


func highlight_interactable(object : Node, highlight : bool):
	var mesh = object.get_node(object.mesh_nodepath)
	
	if highlight:
		#Activate highlight param for each material
		for material in mesh.get_surface_material_count():
			mesh.get_surface_material(material).set_shader_param("highlighted", true)
	else:
		for material in mesh.get_surface_material_count():
			mesh.get_surface_material(material).set_shader_param("highlighted", false)


func raycast_query(from, to, exclude):
	var space_state = get_world().direct_space_state
	var result = space_state.intersect_ray(from, to, [self, exclude])
	return result


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


func _on_input_move_direction_changed_changed(input_direction):
	input_move_direction = input_direction


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


func _on_Interact_System_area_entered(area):
	if area in get_tree().get_nodes_in_group("interactable"):
		nearby_interactables.push_front(area)


func _on_Interact_System_area_exited(area):
	if area in get_tree().get_nodes_in_group("interactable"):
		if area == closest_interactable:
			highlight_interactable(closest_interactable, false)
			closest_interactable = null
		nearby_interactables.erase(area)


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




