extends "res://scripts/State Machine/states/state.gd"

"""
The move state machine rig rotation is desynced from camera rotation
Facing angle may be better emitted from the player state machine
"""

signal camera_moved(camera_transform)
signal camera_direction_changed(camera_direction)
signal focus_direction_changed(focus_direction)
signal view_locked(is_view_locked, centering_time_left)
signal enter_new_view(view_mode)
signal view_blocked(is_obscured)
signal break_target

var initialized_values = {}

#Node Storage
onready var Player = owner.owner
onready var Camera_Rig = owner
onready var Pivot = owner.get_node("Pivot")
onready var Head_Target = owner.get_node("Pivot/Head_Target")
onready var Camera_Position = owner.get_node("Pivot/Cam_Position")
onready var Camera_Position_Default = owner.get_node("Pivot/Cam_Position_Default")
onready var Camera_Position_Target = owner.get_node("Pivot/Cam_Position_Target")

#Node Position Local Defaults
var head_target_offset_default = Vector3(0,0, 10.0)

#State Storage
var state_move
var state_action
var state_move_changed = false
var state_action_changed = false

###Camera Variables
var camera_angle = Vector2() #stores camera global rotation
var camera_position
var camera_rotation = Vector2()
var camera_position_default
var focus_object
var focus_location
var correction_distance = 1

#Joystick Variables
var right_joystick_axis = Vector2(0,0)
var joystick_inner_deadzone = 0.01
var joystick_outer_deadzone = 0.9
var right_joystick_sensitivity = 1.0 #####CONSIDER SETTING THIS A DIFFERENT, GLOBAL WAY
var look_speed = 1.0

#Centering Variables
var centering_turn_radius = deg2rad(25)
var centering_time = 12 #in frames
var centering_time_left = 0
var current_camera_angle = Vector2()
var rotate_angle = Vector2()
var focus_object_position

#Camera Position Interpolation Variables
var interpolation_time = centering_time
var interpolation_time_left = 0

#Targetting Variables
var targetting = false

#View Settings
var view_mode

#View Change Variables
var view_change_time = 10
var view_change_time_left = 0

#Camera Flags
var is_obscured
var centered = false
var centering = false
var view_locked = false
var strafe_locked = false

#Head Variables
var facing_direction = Vector3()
var previous_facing_angle = Vector2()
var focus_direction = Vector2()
var focus_angle = Vector2()
var focus_angle_global = Vector2()

var body_turn_angle = Vector2()


#Initializes state, changes animation, etc
func enter():
	return


#Cleans up state, reinitializes values like timers
func exit():
	return


#Creates output based on the input event passed in
func handle_input(event):
	right_joystick_axis = get_right_joystick_input(event, right_joystick_axis)


#Acts as the _process method would
func update(_delta):
	return


func _on_animation_finished(_anim_name):
	return


func get_body_centering_angle(body_node):
	var facing_angle = body_node.global_transform.basis.get_rotation_quat().get_euler().y
	
	if targetting:
		var target_position = focus_object.global_transform.origin
		var target_angle = calculate_global_y_rotation(owner.global_transform.origin.direction_to(target_position))
		
		###Body Y Rotation
		if !centered:
			if centering_time_left == centering_time:
				body_turn_angle.y = target_angle - facing_angle
				#Turning left at degrees > 180
				if (body_turn_angle.y > deg2rad(180)):
					body_turn_angle.y = body_turn_angle.y - deg2rad(360)
				#Turning right at degrees < -180
				if (body_turn_angle.y < deg2rad(-180)):
					body_turn_angle.y = body_turn_angle.y + deg2rad(360)
				body_turn_angle.y = body_turn_angle.y/centering_time_left
		else:
			body_turn_angle.y = target_angle - facing_angle
	else:
		body_turn_angle.y = 0
		
		
	return body_turn_angle


func get_right_joystick_input(event, current_axis):
	var axis = current_axis
	
	if event is InputEventJoypadMotion and event.get_device() == 0:
		#X Axis
		if event.get_axis() == 2:
			#Inner Deadzone
			if event.get_axis_value() < joystick_inner_deadzone and event.get_axis_value() > -joystick_inner_deadzone:
				axis.x = 0
			#Outer Deadzone
			elif event.get_axis_value() > joystick_outer_deadzone or event.get_axis_value() < -joystick_outer_deadzone:
				axis.x = sign(event.get_axis_value()) * right_joystick_sensitivity
			else:
				axis.x = event.get_axis_value() * right_joystick_sensitivity
		#Y Axis
		if event.get_axis() == 3:
			#Inner Deadzone
			if event.get_axis_value() < joystick_inner_deadzone and event.get_axis_value() > -joystick_inner_deadzone:
				axis.y = 0
			#Outer Deadzone
			elif event.get_axis_value() > joystick_outer_deadzone or event.get_axis_value() < -joystick_outer_deadzone:
				axis.y = sign(event.get_axis_value()) * right_joystick_sensitivity
			else:
				axis.y = event.get_axis_value() * right_joystick_sensitivity
		
	#Input Bounding
	if axis.length() > 1.0:
		axis = axis.normalized()
	
	return axis


func move_head_target(focus_target):
	if focus_target:
		Head_Target.global_transform.origin = focus_target.global_transform.origin
	else:
		var target_pos_local = (Pivot.transform.origin + head_target_offset_default).rotated(Vector3(1,0,0), focus_angle.x)
		Head_Target.global_transform.origin = owner.to_global(target_pos_local)


func reset_recenter():
	centered = false
	centering_time_left = centering_time


func reset_interpolate():
	interpolation_time_left = interpolation_time


func decrement_centering_time():
	#Decrement time left
	if centering_time_left > 0:
		centering_time_left -= 1
	
	#Centering time left is 0 when centered
	if centering_time_left <= 0:
		centered = true


func get_node_direction(node):
	var direction = Vector3(0,0,1)
	var rotate_by = node.global_transform.basis.get_rotation_quat().get_euler()
	direction = direction.rotated(Vector3(1,0,0), rotate_by.x)
	direction = direction.rotated(Vector3(0,1,0), rotate_by.y)
	direction = direction.rotated(Vector3(0,0,1), rotate_by.z)
	
	return direction


func bound_angle(angle):
	#Angle > 180
	if (angle > deg2rad(180)):
		angle = angle - deg2rad(360)
	#Angle < -180
	if (angle < deg2rad(-180)):
		angle = angle + deg2rad(360)
	
	return angle


func calculate_global_y_rotation(direction):
	var test_direction = Vector2(0,1)
	var direction_to = Vector2(direction.x, direction.z)
	var y_rotation = -test_direction.angle_to(direction_to)
	return y_rotation #Output is PI > y > -PI


func calculate_local_x_rotation(direction):
	var test_direction = Vector3(direction.x, 0, direction.z)
	var x_rotation
	
	if direction.y < 0:
		x_rotation = test_direction.angle_to(direction)
	else:
		x_rotation = -test_direction.angle_to(direction)
	
	return x_rotation


func connect_camera_signals():
	owner.get_node("State_Machine").connect("initialized_values_dic_set", self, "on_State_Machine_initialized_values_set")
	Player.connect("entered_new_view", self, "_on_Player_entered_new_view")
	Camera_Rig.connect("focus_target", self, "_on_Nikkiv2_focus_target")
	owner.owner.get_node("State_Machine_Move").connect("move_state_changed", self, "_on_State_Machine_Move_state_changed")
	owner.owner.get_node("State_Machine_Action").connect("action_state_changed", self, "_on_State_Machine_Action_state_changed")


func disconnect_camera_signals():
	owner.get_node("State_Machine").disconnect("initialized_values_dic_set", self, "on_State_Machine_initialized_values_set")
	Player.disconnect("entered_new_view", self, "_on_Player_entered_new_view")
	Camera_Rig.disconnect("focus_target", self, "_on_Nikkiv2_focus_target")
	owner.owner.get_node("State_Machine_Move").disconnect("move_state_changed", self, "_on_State_Machine_Move_state_changed")
	owner.owner.get_node("State_Machine_Action").disconnect("action_state_changed", self, "_on_State_Machine_Action_state_changed")


func set_initialized_values(init_values_dic):
	for value in init_values_dic:
		init_values_dic[value] = self[value]


func on_State_Machine_initialized_values_set(init_values_dic):
	initialized_values = init_values_dic


func _on_Player_entered_new_view(view_state):
	if view_state == "first_person":
		view_locked = false


func _on_Nikkiv2_focus_target(target_pos_node):
	if target_pos_node:
		focus_object = target_pos_node
		Head_Target.global_transform.origin = focus_object.global_transform.origin
		targetting = true
#		centering = true
	else:
		focus_object = target_pos_node
		targetting = false
#		centering = false


func _on_State_Machine_Move_state_changed(move_state):
	state_move = move_state

func _on_State_Machine_Action_state_changed(action_state):
	#Do something on exiting old state:
	if state_action == "Bow":
		reset_interpolate()
	
	state_action = action_state
	
	#Do something on entering new state:
	if state_action == "Bow":
		reset_interpolate()






