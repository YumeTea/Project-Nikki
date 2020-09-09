extends Spatial

"""
Instead of passing signal to change view along, maybe connect directly to 
camera state machine
"""

#Camera Signals to pass on
signal camera_moved(camera_transform)
signal camera_direction_changed(camera_direction)
signal focus_direction_changed(focus_direction) #passed in from state machine to pass on
signal view_locked(is_view_locked, centering_time_left)
signal enter_new_view(view_mode)
signal view_blocked(is_obscured)
signal break_target

#Player signals to pass on
signal focus_target(focus_target_node)

var focus_starting_angle = Vector2(deg2rad(15), deg2rad(0))
var starting_view_mode = "third_person"


func _ready():
	#Connect to camera state machine values
	for child in $State_Machine.get_children():
		child.connect("camera_moved", self, "_on_State_Machine_camera_moved")
	for child in $State_Machine.get_children():
		child.connect("camera_direction_changed", self, "_on_State_Machine_camera_direction_changed")
	for child in $State_Machine.get_children():
		child.connect("focus_direction_changed", self, "_on_State_Machine_focus_direction_changed")
	for child in $State_Machine.get_children():
		child.connect("view_locked", self, "_on_State_Machine_view_locked")
	for child in $State_Machine.get_children():
		child.connect("enter_new_view", self, "_on_State_Machine_enter_new_view")
	for child in $State_Machine.get_children():
		child.connect("view_blocked", self, "_on_State_Machine_view_blocked")
	for child in $State_Machine.get_children():
		child.connect("break_target", self, "_on_State_Machine_break_target")
	
	#Send initial rotation input to camera
	$State_Machine.get_node($State_Machine.START_STATE).initial_rotate(Vector2(rad2deg(focus_starting_angle.y), rad2deg(focus_starting_angle.x)))
	
	#Get and emit initial camera values
#	var focus_direction = get_node_direction($Pivot/Camera_Position)
#	var camera_direction = get_node_direction($Pivot/Camera_Position)
#	var camera_transform = $Pivot/Camera_Position.get_global_transform()
	
#	emit_signal("camera_moved", camera_transform)
#	emit_signal("camera_direction_changed", camera_direction)
#	emit_signal("focus_direction_changed", focus_direction)
	emit_signal("enter_new_view", starting_view_mode)


func get_node_direction(node):
	var direction = Vector3(0,0,1)
	var rotate_by = node.get_global_transform().basis.get_euler()
	direction = direction.rotated(Vector3(1,0,0), rotate_by.x)
	direction = direction.rotated(Vector3(0,1,0), rotate_by.y)
	direction = direction.rotated(Vector3(0,0,1), rotate_by.z)
	
	return direction


func _on_State_Machine_camera_moved(camera_transform):
	emit_signal("camera_moved", camera_transform)


func _on_State_Machine_camera_direction_changed(camera_direction):
	emit_signal("camera_direction_changed", camera_direction)


func _on_State_Machine_focus_direction_changed(focus_direction):
	emit_signal("focus_direction_changed", focus_direction)


func _on_State_Machine_view_locked(is_view_locked, centering_time_left):
	emit_signal("view_locked", is_view_locked, centering_time_left)


func _on_State_Machine_enter_new_view(view_mode):
	emit_signal("enter_new_view", view_mode)


func _on_State_Machine_view_blocked(is_obscured):
	emit_signal("view_blocked", is_obscured)


func _on_State_Machine_break_target():
	emit_signal("break_target")


func _on_Nikkiv2_focus_target(target_pos_node):
	emit_signal("focus_target", target_pos_node)

