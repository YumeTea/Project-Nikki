extends "res://scenes/Player/player_states/interaction/interaction.gd"


"Velocity rotation is off sometimes"


#Variable Signals
signal position_changed(current_position)
signal velocity_changed(current_velocity)
signal facing_angle_changed(facing_angle)
#Flag Signals
signal started_falling(fall_height)
signal landed(landing_height)
signal center_view(turn_angle)

###Node Storage
onready var world = get_tree().current_scene
onready var Player = owner
onready var Camera_Rig_Position = owner.get_node("Rig/Skeleton/Camera_Rig_Pos")
onready var camera = owner.get_node("Camera_Rig/Pivot/Cam_Position") #should get camera position a different way
onready var Pivot = owner.get_node("Camera_Rig/Pivot")
onready var Rig = owner.get_node("Rig")
onready var skeleton = owner.get_node("Rig/Skeleton")
onready var Player_Collision = owner.get_node("CollisionShape")
onready var Raycast_Floor = owner.get_node("Rig/Raycast_Floor")
onready var animation_state_machine_move = owner.get_node("AnimationTree").get("parameters/StateMachineMove/playback")
#Ledge Grab Nodes
onready var Ledge_Grab_System = owner.get_node("Rig/Ledge_Grab_System")
#Foot IK Nodes
onready var foot_floor_l = owner.get_node("Rig/Skeleton/Foot_Floor_L")
onready var foot_floor_r = owner.get_node("Rig/Skeleton/Foot_Floor_R")
onready var foot_l_cont = owner.get_node("Rig/Skeleton/Foot_IK/Foot_L_Cont")
onready var foot_r_cont = owner.get_node("Rig/Skeleton/Foot_IK/Foot_R_Cont")

#Default Values
onready var Camera_Rig_Position_transform_default = Camera_Rig_Position.transform

#Ledge Grab Variables
var ledge_grab_transform : Transform
var wall_normal : Vector3

#Foot IK Variables
const foot_cont_position_offset = Vector3(0, 0, 0)
const foot_rotation_offset = Vector3(0.113, 0, 0)
const foot_angle_lim = 60

#Slope Correction Variables
"Adjust collider origin when changing values here"
const offset_max_velocity_y = 5.0 #y_velocity where velocity_y_modifier is max
const collider_offset_max = 1.1 #max distance to move ground collider up or down
const collider_offset_default = 3.175 #default y translation of ground collider(local)
const collider_offset_change_limit = 0.1 #max amount collider can move each frame

#Animation Blending Variables
var move_blend_position : float

#Initialized Values Storage
var initialized_values = {}

#World Interaction Variables
var fall_height : float
var land_height : float

#Environment Variables
var ledge_height : float
var ledge_hang_height : float
var surface_height : float
var surfaced_height : float

###Physics Variables
var position : Vector3
var height : float
var direction = Vector3(0,0,0)
var direction_angle = Vector2(0,0)
var velocity = Vector3(0,0,0)
var velocity_horizontal : float
var acceleration_horizontal : float
const gravity = -9.8
const weight = 5
#Walk Variables
var up_direction = Vector3(0,1,0)
const floor_angle_max = deg2rad(50)
var slope_influence = 0.16

#Input Variables
var left_joystick_axis = Vector2(0,0)
var right_joystick_axis = Vector2(0,0)
var joystick_inner_deadzone = 0.01
var joystick_outer_deadzone = 0.9
var left_joystick_sensitivity = 1.0 #####CONSIDER SETTING THIS A DIFFERENT, GLOBAL WAY
var right_joystick_sensitivity = 1.0

##Ground Snap Variables
const snap_vector_default = Vector3(0,-1,0)
var snap_vector = snap_vector_default #Used for Move_and_slide_with_snap

#Centering Variables
const centering_time = 12 #in frames
var centering_time_left = 0
var turn_angle = Vector2()
var focus_angle_lim = Vector2(deg2rad(57.5), deg2rad(82))

#View Change Variables
const view_change_time = 10
var view_change_time_left = 0

#Player Flags
var strafe_locked = false
var can_void = true
var is_moving = false
var is_falling = false
var in_water = false

var centering_view = false
var centered = false
var rotate_to_focus : bool

#Walking Flags
var quick_turn = true

#Ledge Hang Flags
var valid_ledge = false


func enter():
	.enter()


func exit():
	#Reset custom pose overrides and stop IK
	stop_foot_ik(foot_floor_l)
	stop_foot_ik(foot_floor_r)
	
	#Reset changes to camera origin node
	Camera_Rig_Position.transform = Camera_Rig_Position_transform_default
	owner.get_node("Camera_Rig").global_transform.origin = Camera_Rig_Position.global_transform.origin
	
	.exit()


func handle_input(event):
	if event is InputEventJoypadMotion and event.get_device() == 0:
		left_joystick_axis = get_left_joystick_input(event, left_joystick_axis)
		right_joystick_axis = get_right_joystick_input(event, right_joystick_axis)
	
	if Input.is_action_pressed("center_view"):
		centering_view = true
		if event.is_action_pressed("center_view") and event.get_device() == 0:
			reset_recenter()
	else: #checks all input to see if released, not just event
		centered = false
		centering_view = false
	
	if event.is_action_pressed("switch_view") and event.get_device() == 0 and view_mode == "first_person":
		rotate_to_focus = true
		reset_view_change_time()
	
	.handle_input(event)


func update(delta):
	###Set held direction
	direction = get_input_direction()
	
#	if Raycast_Floor.is_colliding():
#		if direction.angle_to(Raycast_Floor.get_collision_normal()) >= deg2rad(90):
#			print(direction.normalized().cross(Raycast_Floor.get_collision_normal()).length())
#		else:
#			print(-direction.normalized().cross(Raycast_Floor.get_collision_normal()).length())
	
	###Player Motion
	velocity = Player.move_and_slide_with_snap(velocity, snap_vector, up_direction, true, 1, floor_angle_max, false) #Come back/check vars 3,4,5
	
	###Player Slope Adjustment
	adjust_to_ground()
	
	###Foot IK
	run_foot_ik()
	
	###Motion Value Assignments
	position = Player.global_transform.origin
	acceleration_horizontal = Vector2(velocity.x, velocity.z).length() - velocity_horizontal
	velocity_horizontal = Vector2(velocity.x, velocity.z).length()
	height = position.y
	
	###Player Value Assignment
	facing_direction = get_node_direction(Rig)
	
	#Signal Emission
	emit_signal("position_changed", position)
	emit_signal("velocity_changed", velocity)
	
	.update(delta)


func on_animation_finished(_anim_name):
	return


#Returns direction relative to camera view angle
func get_input_direction():
	direction = Vector3() #Resets direction of player to default
	
	###Camera Direction
	var aim = camera.get_global_transform().basis.get_euler()
	
	###Directional Input
	direction.z -= left_joystick_axis.y
	direction.x -= left_joystick_axis.x
	
	direction = direction.rotated(Vector3(0,1,0), (aim.y + PI))
	
	direction.y = 0
	
	var direction_length = (direction.length())
	if direction_length > 1.0:
		direction_length = 1.0
	
	var direction_normalized = direction.normalized()
	direction = direction_normalized * direction_length
	
	emit_signal("input_move_direction_changed", direction)
	
	return direction


func get_left_joystick_input(event, current_axis):
	var axis = current_axis
	
	if event is InputEventJoypadMotion and event.get_device() == 0:
		#X Axis
		if event.get_axis() == 0:
			#Inner Deadzone
			if event.get_axis_value() < joystick_inner_deadzone and event.get_axis_value() > -joystick_inner_deadzone:
				axis.x = 0
			#Outer Deadzone
			elif event.get_axis_value() > joystick_outer_deadzone or event.get_axis_value() < -joystick_outer_deadzone:
				axis.x = sign(event.get_axis_value()) * left_joystick_sensitivity
			else:
				axis.x = event.get_axis_value() * left_joystick_sensitivity
		#Y Axis
		if event.get_axis() == 1:
			#Inner Deadzone
			if event.get_axis_value() < joystick_inner_deadzone and event.get_axis_value() > -joystick_inner_deadzone:
				axis.y = 0
			#Outer Deadzone
			elif event.get_axis_value() > joystick_outer_deadzone or event.get_axis_value() < -joystick_outer_deadzone:
				axis.y = sign(event.get_axis_value()) * left_joystick_sensitivity
			else:
				axis.y = event.get_axis_value() * left_joystick_sensitivity
		
	#Input Bounding
	if axis.length() > 1.0:
		axis = axis.normalized()
		
	return axis


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


func calculate_movement_velocity(delta):
	###Velocity Calculation
	var temp_velocity = velocity
	temp_velocity.y = 0.0
	
	###Target Velocity
	var target_velocity = direction * speed
	#Speed Cap
	if abs(target_velocity.length()) > speed_default:
		target_velocity = target_velocity.normalized() * speed_default
	
	###Determine the type of acceleration
	var acceleration
	if direction.dot(temp_velocity) > 0 or temp_velocity == Vector3(0,0,0):
		acceleration = ACCEL
	else:
		acceleration = DEACCEL
	
	#Calculate a portion of the distance to go
	temp_velocity = temp_velocity.linear_interpolate(target_velocity, acceleration * delta)
	
	###Final Velocity
	if temp_velocity.length() > 0.01:
		velocity.x = temp_velocity.x
		velocity.z = temp_velocity.z
	else:
		velocity.x = 0.0
		velocity.z = 0.0
	
	##Gravity
	var floor_angle = Raycast_Floor.get_collision_normal().angle_to(Vector3.UP)
	var floor_normal = Raycast_Floor.get_collision_normal()
	floor_normal.x = stepify(floor_normal.x, 0.001)
	floor_normal.y = stepify(floor_normal.y, 0.001)
	floor_normal.z = stepify(floor_normal.z, 0.001)
	
	
	#Up Direction
	if (owner.is_on_floor() or snap_vector_is_colliding()) and floor_angle <= floor_angle_max: #Special gravity if on slope and slope is within floor_angle_max
		up_direction = floor_normal #Player will fall toward valid slopes, essentially sticking to them
	else: #Default gravity on floors over floor_angle_max
		up_direction = Vector3.UP
	
	snap_vector = -up_direction
	var g = up_direction * gravity
	velocity += weight * g * delta
	
	#Slope Velocity Modifier
	var slope_modifier
	
	if Raycast_Floor.is_colliding() and direction != Vector3(0,0,0):
		#Uphill
		if direction.angle_to(floor_normal) >= deg2rad(90):
			slope_modifier = direction.normalized().cross(floor_normal).length()
			slope_modifier += (1.0 - slope_modifier) * (1.0 - slope_influence)
			velocity *= slope_modifier
		#Downhill
		else:
			slope_modifier = direction.normalized().cross(floor_normal).length()
			slope_modifier = 1.0 + (1.0 - slope_modifier) * (1.0 - slope_influence)
			velocity += velocity * slope_modifier * delta


func calculate_aerial_velocity(delta):
	###Velocity Calculation
	var temp_velocity = velocity
	temp_velocity.y = 0.0
	
	###Target Velocity
	var target_velocity = temp_velocity + (direction * speed_aerial)
	
	if temp_velocity.dot(direction) >= 0.0:
		if abs(temp_velocity.length()) > speed_default: #Preserve speed if past max speed
			target_velocity = temp_velocity
		elif target_velocity.length() > speed_default: #Speed cap at max speed if under max speed
			target_velocity = target_velocity.normalized() * speed_default
	
	
	###Determine the type of acceleration
	var acceleration
	acceleration = ACCEL
	
	#Calculate a portion of the distance to go
	temp_velocity = temp_velocity.linear_interpolate(target_velocity, acceleration * delta)
	
	###Final Velocity
	if temp_velocity.length() > 0.01:
		velocity.x = temp_velocity.x
		velocity.z = temp_velocity.z
	else:
		velocity.x = 0.0
		velocity.z = 0.0
	
	velocity.y += weight * gravity * delta


func calculate_ledge_velocity(delta):
	###Velocity Calculation
	var temp_velocity = velocity
	temp_velocity.y = 0

	###Target Velocity
	var target_velocity = direction * speed
	#Speed Cap
	if abs(target_velocity.length()) > speed_default:
		target_velocity = target_velocity.normalized() * speed_default

	###Determine the type of acceleration
	var acceleration
	if direction.dot(temp_velocity) > 0 or temp_velocity == Vector3(0,0,0):
		acceleration = ACCEL
	else:
		acceleration = DEACCEL

	#Calculate a portion of the distance to go
	temp_velocity = temp_velocity.linear_interpolate(target_velocity, acceleration * delta)

	###Final Velocity
	if temp_velocity.length() <= 0.01:
		temp_velocity.x = 0.0
		temp_velocity.z = 0.0
		
	return temp_velocity


func calculate_swim_velocity(delta):
	var temp_velocity = velocity
	temp_velocity.y = 0
	
	###Target Velocity
	var target_velocity = direction * speed_swim
	#Speed Cap
	if abs(target_velocity.length()) > speed_default:
		target_velocity = target_velocity.normalized() * speed_default
	
	###Determine the type of acceleration
	var acceleration
	if direction.dot(temp_velocity) > 0 or temp_velocity == Vector3(0,0,0):
		acceleration = ACCEL
	else:
		acceleration = DEACCEL
	
	#Calculate a portion of the distance to go
	temp_velocity = temp_velocity.linear_interpolate(target_velocity, acceleration * delta)
	
	###Final Velocity
	if temp_velocity.length() > 0.01:
		velocity.x = temp_velocity.x
		velocity.z = temp_velocity.z
	else:
		velocity.x = 0.0
		velocity.z = 0.0
	
	if Player.global_transform.origin.y < surfaced_height:
		velocity.y += surface_accel * delta
		if velocity.y > surface_speed:
			velocity.y = surface_speed
	else:
		Player.global_transform.origin.y = surfaced_height


func run_foot_ik():
	#Get origin of foot_floor bones
	var foot_floor_l_transform = skeleton.get_bone_global_pose(skeleton.find_bone("foot_floor_ik_l"))
	var foot_floor_r_transform = skeleton.get_bone_global_pose(skeleton.find_bone("foot_floor_ik_r"))
	
	#Set foot controllers to default keyframe position
	foot_l_cont.transform.origin = foot_floor_l_transform.origin
	foot_r_cont.transform.origin = foot_floor_r_transform.origin
	foot_l_cont.transform.basis = Basis(Vector3(1,0,0), Vector3(0,1,0), Vector3(0,0,1))
	foot_r_cont.transform.basis = Basis(Vector3(1,0,0), Vector3(0,1,0), Vector3(0,0,1))
	
	###Left Foot Correction
	if foot_floor_l.get_node("Foot_L_Raycast").is_colliding():
		var normal_dot_up = Vector3(0,1,0).dot(foot_floor_l.get_node("Foot_L_Raycast").get_collision_normal())
		
		#Check if floor angle is valid for foot placement
		if normal_dot_up > (90.0 - foot_angle_lim) / 90.0:
			##Calculate new foot controller global transform
			#Origin
			var foot_transform = foot_l_cont.get_global_transform()
			foot_transform.origin = foot_floor_l.get_node("Foot_L_Raycast").get_collision_point()
			
			#Height Offset of IK'd bone
			foot_transform.origin += foot_cont_position_offset
			
			#Rotation
			var floor_normal = foot_floor_l.get_node("Foot_L_Raycast").get_collision_normal()
			foot_transform.basis = align_up(foot_transform.basis, floor_normal)
			
			#Set new transform
			foot_l_cont.set_global_transform(foot_transform)
			
			#Start IK
			owner.get_node("Rig/Skeleton/SkeletonIK_Foot_L").start()
			
			pose_override(skeleton.find_bone("talus_l"), true)
			pose_override(skeleton.find_bone("foot_l"), true)
		else:
			stop_foot_ik(foot_floor_l)
	else:
		stop_foot_ik(foot_floor_l)
	
	###Right Foot Correction
	if foot_floor_r.get_node("Foot_R_Raycast").is_colliding():
		var normal_dot_up = Vector3(0,1,0).dot(foot_floor_r.get_node("Foot_R_Raycast").get_collision_normal())
		
		#Check if floor angle is valid for foot placement
		if normal_dot_up > (90.0 - foot_angle_lim) / 90.0:
			##Calculate new foot controller global transform
			#Origin
			var foot_transform = foot_r_cont.get_global_transform()
			foot_transform.origin = foot_floor_r.get_node("Foot_R_Raycast").get_collision_point()
			
			#Height Offset of IK'd bone
			foot_transform.origin += foot_cont_position_offset
			
			#Rotation
			var floor_normal = foot_floor_r.get_node("Foot_R_Raycast").get_collision_normal()
			foot_transform.basis = align_up(foot_transform.basis, floor_normal)
			
			#Set new foot global transform
			foot_r_cont.set_global_transform(foot_transform)
			
			#Start IK
			owner.get_node("Rig/Skeleton/SkeletonIK_Foot_R").start()
			
			pose_override(skeleton.find_bone("talus_r"), true)
			pose_override(skeleton.find_bone("foot_r"), true)
		else:
			stop_foot_ik((foot_floor_r))
	else:
		stop_foot_ik(foot_floor_r)


func stop_foot_ik(foot_floor_attachment):
	if foot_floor_attachment == foot_floor_l:
		owner.get_node("Rig/Skeleton/SkeletonIK_Foot_L").stop()
		skeleton.clear_bones_global_pose_override()
		pose_override(skeleton.find_bone("talus_l"), false)
		pose_override(skeleton.find_bone("foot_l"), false)
	
	if foot_floor_attachment == foot_floor_r:
		owner.get_node("Rig/Skeleton/SkeletonIK_Foot_R").stop()
		skeleton.clear_bones_global_pose_override()
		pose_override(skeleton.find_bone("talus_r"), false)
		pose_override(skeleton.find_bone("foot_r"), false)


func pose_override(bone_idx, on_bool : bool):
	if on_bool:
		var current_pose = skeleton.get_bone_pose(bone_idx)
		var zeroed_pose = current_pose.looking_at(Vector3(0,0,1), Vector3(0,1,0))
		
		#Find difference between flat foot pose and current anim pose
		var override_pose = Transform()
		#Origin
		override_pose.origin = zeroed_pose.origin - current_pose.origin
		
		#X
		override_pose.basis.x = zeroed_pose.basis.x - current_pose.basis.x
		override_pose.basis.x.x = 1.0
		
		#Y
		override_pose.basis.y = zeroed_pose.basis.y - current_pose.basis.y
		override_pose.basis.y.y = 1.0
		
		#Z
		override_pose.basis.z = zeroed_pose.basis.z - current_pose.basis.z 
		override_pose.basis.z.z = 1.0
		
		#Set overriding custom pose
		skeleton.set_bone_custom_pose(bone_idx, override_pose)
	else:
		#Reset custom pose
		skeleton.set_bone_custom_pose(bone_idx, Transform())


func adjust_to_ground():
	var floor_raycast = owner.get_node("Rig/Raycast_Floor")
	var velocity_y_modifier = clamp(velocity.y, -offset_max_velocity_y, offset_max_velocity_y) / offset_max_velocity_y
	var offset
	var offset_current = Player_Collision.transform.origin.y
	
	if floor_raycast.is_colliding():
		var floor_normal = floor_raycast.get_collision_normal()
		var floor_angle = -calculate_local_x_rotation(floor_normal) # 0 > PI
		
		#Calculate and bound offset if necessary
		offset = (floor_angle / PI * velocity_y_modifier * collider_offset_max) + collider_offset_default
		offset = abs(offset)
		
		if abs(offset_current - offset) > collider_offset_change_limit:
			offset = offset_current + (collider_offset_change_limit * sign(offset - offset_current))
		
		#Move collision
		Player_Collision.transform.origin.y = offset
		
		#Calc how much collision moved and move player object y by opposite amount
		var offset_change = offset_current - offset
		
		owner.transform.origin.y += offset_change
		
	else:
		#Calculate and bound offset if necessary
		offset = offset_current - (offset_current - collider_offset_default)
		
		if abs(offset_current - offset) > collider_offset_change_limit:
			offset = offset_current + (collider_offset_change_limit * sign(offset - offset_current))
		
		#Move collision
		Player_Collision.transform.origin.y = offset


#Returns true if ground snap vector is touching something
func snap_vector_is_colliding():
	var from_point = Player_Collision.global_transform.origin
	from_point.y -= Player_Collision.transform.origin.y
	
	var to_point = from_point + snap_vector
	
	var obstruction = raycast_query(from_point, to_point, self)
	if obstruction.empty():
		return false
	else:
		return true


func reset_recenter():
	centered = false
	centering_time_left = centering_time


func reset_view_change_time():
	centered = false
	view_change_time_left = view_change_time


func set_initialized_values(init_values_dic):
	for value in init_values_dic:
		init_values_dic[value] = self[value]


#####EXTERNAL INPUT FUNCTIONS#####
func connect_player_signals():
	#Player Signals
	owner.get_node("AnimationTree").connect("animation_started", self, "on_animation_started")
	owner.get_node("AnimationTree").connect("animation_finished", self, "on_animation_finished")
	owner.connect("focus_target", self, "_on_Player_focus_target_changed")
	owner.get_node("State_Machine_Move").connect("initialized_values_dic_set", self, "_on_State_Machine_Move_initialized_values_dic_set")
	owner.get_node("State_Machine_Move").connect("move_state_changed", self, "_on_State_Machine_Move_state_changed")
	owner.get_node("State_Machine_Action").connect("action_state_changed", self, "_on_State_Machine_Action_state_changed")
	owner.get_node("Camera_Rig").connect("camera_direction_changed", self, "_on_Camera_Rig_camera_direction_changed")
	owner.get_node("Camera_Rig").connect("view_locked", self, "_on_Camera_Rig_view_locked")
	owner.get_node("Camera_Rig").connect("enter_new_view", self, "_on_Camera_Rig_enter_new_view")
	owner.get_node("Attributes/Health").connect("health_depleted", self, "_on_Player_death")
	owner.get_node("Rig/Ledge_Grab_System").connect("ledge_grab_point", self, "_on_Ledge_Grab_System_ledge_grab_point")
	
	#World Signals
	owner.connect("entered_area", self, "_on_environment_area_entered")
	owner.connect("exited_area", self, "_on_environment_area_exited")
	
	#Global Signals
	GameManager.connect("player_respawned", self, "_on_GameManager_player_respawned")
	GameManager.connect("player_voided", self, "_on_GameManager_player_voided")


func disconnect_player_signals():
	#Player Signals
	owner.get_node("AnimationTree").disconnect("animation_started", self, "on_animation_started")
	owner.get_node("AnimationTree").disconnect("animation_finished", self, "on_animation_finished")
	owner.disconnect("focus_target", self, "_on_Player_focus_target_changed")
	owner.get_node("State_Machine_Move").disconnect("initialized_values_dic_set", self, "_on_State_Machine_Move_initialized_values_dic_set")
	owner.get_node("State_Machine_Move").disconnect("move_state_changed", self, "_on_State_Machine_Move_state_changed")
	owner.get_node("State_Machine_Action").disconnect("action_state_changed", self, "_on_State_Machine_Action_state_changed")
	owner.get_node("Camera_Rig").disconnect("camera_direction_changed", self, "_on_Camera_Rig_camera_direction_changed")
	owner.get_node("Camera_Rig").disconnect("view_locked", self, "_on_Camera_Rig_view_locked")
	owner.get_node("Camera_Rig").disconnect("enter_new_view", self, "_on_Camera_Rig_enter_new_view")
	owner.get_node("Attributes/Health").disconnect("health_depleted", self, "_on_Player_death")
	owner.get_node("Rig/Ledge_Grab_System").disconnect("ledge_grab_point", self, "_on_Ledge_Grab_System_ledge_grab_point")
	
	#World Signals
	owner.disconnect("entered_area", self, "_on_environment_area_entered")
	owner.disconnect("exited_area", self, "_on_environment_area_exited")
	
	#Global Signals
	GameManager.disconnect("player_respawned", self, "_on_GameManager_player_respawned")
	GameManager.disconnect("player_voided", self, "_on_GameManager_player_voided")


###PLAYER SIGNAL FUNCTIONS###

func _on_Player_focus_target_changed(target_pos_node):
	focus_object = target_pos_node


func _on_State_Machine_Move_initialized_values_dic_set(init_values_dic):
	initialized_values = init_values_dic


func _on_State_Machine_Move_state_changed(move_state):
	state_move = move_state


func _on_State_Machine_Action_state_changed(action_state):
	#Before changing state
	if state_action in strafe_locked_states:
		strafe_locked = false
		is_moving = false
		quick_turn = true
	
	#Store new action state
	state_action = action_state
	
	#After changing state
	if action_state == "None":
		#Removes walk blend tween as active so tween is only started once in walk.gd
		remove_active_tween("parameters/StateMachineMove/Walk/BlendSpace1D/blend_position")
	
	if action_state in strafe_locked_states:
		strafe_locked = true
		#Change walk speed if in certain action states
		if action_state in ["Bow"]:
			speed = speed_bow_walk
		
		#Remove Lower Body active tween so it starts once on entering bow state
		remove_active_tween("parameters/StateMachineMove/Walk/BlendSpace1D/blend_position")


func _on_Camera_Rig_camera_direction_changed(dir):
	camera_direction = dir


func _on_Camera_Rig_view_locked(is_view_locked, _time_left):
	if !strafe_locked:
		centering_view = is_view_locked
		strafe_locked = is_view_locked
		centered = false
	elif !(state_action in strafe_locked_states): #only turn off strafe locked if outside a strafe locked state
		centering_view = is_view_locked
		strafe_locked = is_view_locked


func _on_Camera_Rig_enter_new_view(string):
	view_mode = string
	if view_mode == "first_person":
		rotate_to_focus = true
	if view_mode == "third_person":
		return


func _on_Ledge_Grab_System_ledge_grab_point(transform, normal):
	ledge_grab_transform = transform
	wall_normal = normal
	
	if (state_move in ["Fall", "Swim"]) and Ledge_Grab_System.get_node("Timer").is_stopped():
		emit_signal("finished", "ledge_hang")


func _on_Player_death(death):
	if death:
		emit_signal("finished", "death")


###WORLD SIGNAL FUNCTIONS###

func _on_environment_area_entered(area_type, surface_h):
	if area_type == "Water":
		in_water = true
		surface_height = surface_h
		surfaced_height = surface_height - player_height


func _on_environment_area_exited(area_type):
	if area_type == "Water":
		in_water = false


func _on_GameManager_player_respawned():
	can_void = true
	emit_signal("finished", "walk")


func _on_GameManager_player_voided():
	if can_void:
		emit_signal("finished", "void")
		can_void = false















#Could be used for smoothing keyboard/dpad input
#func get_input_direction_square():
#	direction = Vector3()
#	var direction_length
#
#	###Camera Direction
#	var aim = camera.global_transform.basis.get_euler()
#
#	###Directional Input
#	direction.z -= left_joystick_axis.y
#	direction.x -= left_joystick_axis.x
#
#	direction = direction.rotated(Vector3(0,1,0), (aim.y + PI))
#	direction.y = 0.0
#
#	#Direction Limiting
#	var input_angle = 0.0
#	var input_max
#
#
#	if direction.z > 0:
#		if direction.x == 0:
#			input_max = 1.0
#		#Up
#		elif direction.z >= direction.x and -direction.z < direction.x:
#			input_angle = acos(direction.z / Vector2(direction.x, direction.z).length())
#			input_max = 1.0 / cos(input_angle)
#		#Left
#		elif direction.x > direction.z:
#			input_angle = acos(direction.x / Vector2(direction.x, direction.z).length())
#			input_max = 1.0 / cos(input_angle)
#		#Right
#		elif direction.x < -direction.z:
#			input_angle = acos(direction.x / Vector2(direction.x, direction.z).length())
#			input_max = -1.0 / cos(input_angle)
#	elif direction.z < 0:
#		if direction.x == 0:
#			input_max = 1.0
#		#Down
#		elif -direction.z >= direction.x and direction.z < direction.x: 
#			input_angle = acos(direction.z / Vector2(direction.x, direction.z).length())
#			input_max = -1.0 / cos(input_angle)
#		#Left
#		elif direction.x > -direction.z:
#			input_angle = acos(direction.x / Vector2(direction.x, direction.z).length())
#			input_max = 1.0 / cos(input_angle)
#		#Right
#		elif direction.x < direction.z:
#			input_angle = acos(direction.x / Vector2(direction.x, direction.z).length())
#			input_max = -1.0 / cos(input_angle)
#	else:
#		input_max = 1.0
#
#	direction_length = direction.length() / input_max
#
#	direction = direction.normalized()
#
#	direction *= direction_length
#
#	return direction
