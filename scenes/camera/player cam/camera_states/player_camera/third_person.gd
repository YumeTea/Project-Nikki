extends "res://scenes/camera/player cam/camera_states/player_camera/player_camera.gd"

"""
Find a better way to get and store default camera position values
Camera_targetting_travel is still applied on global instead of local coordinates
"""

var pivot_pos_default_local = Vector3(0,0,0)
var camera_pos_default_local = Vector3(0,0,-8.5)

var focus_starting_angle = Vector2(deg2rad(15), deg2rad(0))
var focus_angle_lim = Vector2(deg2rad(57.5), deg2rad(360))

#Camera Targetting Travel Variables
var camera_targetting_offset = Vector3(-1.5, 0.5, 0.0)
var camera_targetting_travel = Vector3(0.0, 0.0, 2.0) 
var target_distance_lower_lim = 10.0
var target_distance_upper_lim = 80.0

func initialize(init_values_dic):
	for value in init_values_dic:
		self[value] = init_values_dic[value]


#Initializes state, changes animation, etc
func enter():
	view_mode = "third_person"
	
	#Initial values for rotate function
	if !previous_facing_angle:
		previous_facing_angle = Vector2()
		previous_facing_angle.y = calculate_global_y_rotation(facing_direction)
		previous_facing_angle.x = calculate_local_x_rotation(facing_direction)
	
	#More initial values after initial rotation
	facing_direction = get_node_direction(Player.get_node("Rig"))
	
	#Initial values for displays/targetting
	camera_position_default = Camera_Position_Default.global_transform.origin
	focus_location = Pivot.global_transform.origin
	focus_direction = get_node_direction(Pivot)
	
	#Emit signals to switch view along with current camera values
	emit_signal("enter_new_view", view_mode)
	emit_signal("camera_moved", Camera_Position.global_transform)
	emit_signal("camera_direction_changed", -get_node_direction(Camera_Position))
	emit_signal("focus_direction_changed", focus_direction)
	
	connect_camera_signals()


#Cleans up state, reinitializes values like timers
func exit():
	disconnect_camera_signals()


#Creates output based on the input event passed in
func handle_input(event):
	#Switch View Input
	if event.is_action_pressed("switch_view") and event.get_device() == 0:
		view_change_time_left = view_change_time
		emit_signal("finished", "first_person")
	
	#Center View Input
	if Input.is_action_pressed("center_view"):
		strafe_locked = true
		centering = true
		if event.is_action_pressed("center_view") and event.get_device() == 0:
			centered = false
			reset_recenter()
			reset_interpolate()
		emit_signal("view_locked", strafe_locked, centering_time_left)
	else:
		strafe_locked = false
		centering = false
		reset_recenter()
		if targetting:
			reset_interpolate()
		emit_signal("view_locked", strafe_locked, centering_time_left)
	
	if event.is_action_pressed("lock_target") and event.get_device() == 0:
		reset_recenter()
		reset_interpolate()
	
	.handle_input(event)


#Acts as the _process method would
func update(_delta):
	if view_change_time_left > 0:
		enter_third_person()
	look_third_person()
	.update(_delta)


func _on_animation_finished(_anim_name):
	return


func enter_third_person():
	Camera_Position.get_node("CollisionShape").disabled = false
	
	var camera_pos
	
	if view_change_time_left > 0:
		if (targetting and centering):
			#Get transform of camera if it were in targetting and centering position
			camera_pos = Pivot.to_local(get_camera_targetting_transform(Camera_Rig.to_global(pivot_pos_default_local), 0.0, true).origin)
		elif aiming:
			#Get transform of camera if it were in aiming position
			camera_pos = Pivot.to_local(get_camera_aim_transform().origin)
		else:
			#Get default third person camera transform
			camera_pos = camera_pos_default_local
		
		var pivot_move = (pivot_pos_default_local - Pivot.transform.origin) / view_change_time_left
		var head_target_move = ((Pivot.transform.origin + head_target_offset_default) - Head_Target.transform.origin) / view_change_time_left
		var camera_move = (camera_pos - Camera_Position.transform.origin) / view_change_time_left
		var camera_default_move = (camera_pos - Camera_Position_Default.transform.origin) / view_change_time_left
		
		Pivot.transform.origin += pivot_move
		Head_Target.transform.origin += pivot_move
		Camera_Position.transform.origin += camera_move
		Camera_Position_Default.transform.origin += camera_default_move
		
		if targetting and centering:
			#If targetting, find end angle of pivot after view mode switch
			var target_direction = Camera_Rig.to_global(pivot_pos_default_local).direction_to(focus_object.global_transform.origin)
			var target_angle = Vector2()
			var centering_angle = Vector2()
			target_angle.x = calculate_local_x_rotation(target_direction)
			centering_angle.x = (target_angle.x - calculate_local_x_rotation(get_node_direction(Pivot))) / view_change_time_left
			
			Pivot.rotate_x(centering_angle.x)
			focus_angle.x += centering_angle.x
		
	view_change_time_left -= 1
	
	if view_change_time_left <= 0:
		emit_signal("entered_new_view", view_mode)


func look_third_person():
	#Move head target before moving camera
	move_head_target(focus_object)
	
	if view_change_time_left > 0:
		enter_third_person()
	elif centering and targetting:
		center_camera()
		interpolate_camera_default_pos(get_camera_targetting_transform(Pivot.global_transform.origin, interpolation_time_left, true), interpolation_time_left)
	elif aiming:
		rotate_camera(right_joystick_axis)
		interpolate_camera_default_pos(get_camera_aim_transform(), interpolation_time_left)
	elif centering:
		center_camera()
		var transform = Pivot.global_transform
		transform.origin = Pivot.to_global(Pivot.transform.origin + camera_pos_default_local)
		interpolate_camera_default_pos(transform, interpolation_time_left)
	else:
		rotate_camera(right_joystick_axis)
		var transform = Pivot.global_transform
		transform.origin = Pivot.to_global(Pivot.transform.origin + camera_pos_default_local)
		interpolate_camera_default_pos(transform, interpolation_time_left)
		
	#Move camera if colliding or line to player is blocked
	camera_collision_correction(Camera_Position, Pivot, Camera_Position_Default)
	
	#Move head target after moving camera
	move_head_target(focus_object)
	
	#Tell free camera if default view is obscured
	if is_obscured:
		emit_signal("view_blocked", is_obscured)
	
	#Tell free camera that camera position has moved
	emit_signal("camera_moved", Camera_Position.global_transform)
	emit_signal("camera_direction_changed", -get_node_direction(Camera_Position))
	emit_signal("focus_direction_changed", focus_direction)


func rotate_camera(input_change):
	var focus_angle_change = Vector2(0,0)
	var turn_angle = Vector2()
	var facing_direction = get_node_direction(Player.get_node("Rig"))
	var facing_angle = Vector2()
	
	focus_direction = get_node_direction(Pivot)
	focus_angle_global.y = calculate_global_y_rotation(focus_direction)
	focus_angle_global.x = calculate_local_x_rotation(focus_direction)
	facing_angle.y = calculate_global_y_rotation(facing_direction)
	facing_angle.x = calculate_local_x_rotation(facing_direction)
	
	###Focus angle body rotation correction
	var facing_angle_change = Vector2()
	
	###Y Focus Angle Limiting
	facing_angle_change.y = previous_facing_angle.y - facing_angle.y
	facing_angle_change.y = bound_angle(facing_angle_change.y)
	
	#Change focus angle if body rotated
	if(focus_angle.y + facing_angle_change.y) < focus_angle_lim.y and (focus_angle.y + facing_angle_change.y) > -focus_angle_lim.y:
		focus_angle.y += facing_angle_change.y
	else: #If facing angle goes outside focus cone, rotate camera rig
		focus_angle_change.y = (sign(focus_angle.y) * focus_angle_lim.y) - focus_angle.y
		focus_angle.y += focus_angle_change.y
		turn_angle.y = -facing_angle_change.y + focus_angle_change.y
		
		Camera_Rig.rotate_y(turn_angle.y)
	
	
	###Focus Input Handling (Actual rotation based on input)
	if input_change.length() > 0:
		var angle_change = Vector2()
	
		angle_change.y = deg2rad(-input_change.x)
		if focus_angle.y + angle_change.y <= focus_angle_lim.y and focus_angle.y + angle_change.y >= -focus_angle_lim.y:
			owner.rotate_y(deg2rad(-input_change.x))
			focus_angle.y += angle_change.y
		else:
			owner.rotate_y((focus_angle_lim.y * sign(focus_angle.y)) - focus_angle.y)
			focus_angle.y += ((focus_angle_lim.y * sign(focus_angle.y)) - focus_angle.y)
	
		angle_change.x = deg2rad(input_change.y)
		if focus_angle.x + angle_change.x <= focus_angle_lim.x and focus_angle.x + angle_change.x >= -focus_angle_lim.x:
			Pivot.rotate_x(deg2rad(input_change.y))
			focus_angle.x += angle_change.x
		else:
			Pivot.rotate_x((focus_angle_lim.x * sign(focus_angle.x)) - focus_angle.x)
			focus_angle.x += ((focus_angle_lim.x * sign(focus_angle.x)) - focus_angle.x)
	
	
	###Focus angle bounding (keep focus angle between -PI > 0 > PI)
	focus_angle.y = bound_angle(focus_angle.y)
	focus_angle.x = bound_angle(focus_angle.x)
	
	
	#Update previous facing angle and focus direction
	previous_facing_angle.y = calculate_global_y_rotation(get_node_direction(Player.get_node("Rig")))
	previous_facing_angle.x = calculate_local_x_rotation(get_node_direction(Player.get_node("Rig")))
	focus_direction = get_node_direction(Pivot)


#Pivot transform is argument for going between first and third person
func get_camera_targetting_transform(pivot_global_transform_origin, interp_time_left, calc_travel):
	#Calc head target pos and distance
	var head_target_pos = Head_Target.global_transform.origin
	
	#Camera Offsetting
	var camera_offset = camera_pos_default_local + camera_targetting_offset
	
	#Calc intended final camera transform
	var transform = Transform()
	transform.origin = Pivot.to_global(pivot_pos_default_local + camera_offset)
	transform = transform.looking_at(head_target_pos, Vector3(0,1,0))
	
	if calc_travel:
		transform = target_camera_travel(focus_object, transform, pivot_global_transform_origin)
	
	return transform


func get_camera_aim_transform():
	#Calc head target pos and distance
	var head_target_pos = Head_Target.global_transform.origin
	
	#Camera Offsetting
	var camera_offset = camera_pos_default_local + camera_targetting_offset
	
	#Calc intended final camera transform
	var transform = Transform()
	transform.origin = Pivot.to_global(pivot_pos_default_local + camera_offset)
	transform = transform.looking_at(head_target_pos, Vector3(0,1,0))
	
	return transform


func target_camera_travel(target, camera_transform_final, pivot_global_transform_origin):
	var target_distance = (pivot_global_transform_origin - Head_Target.global_transform.origin).length()
	var transform = camera_transform_final
	Camera_Position_Target.global_transform = transform
	
	var travel
	
	if target_distance <= target_distance_lower_lim:
		travel = camera_targetting_travel
	
	elif target_distance > target_distance_lower_lim and target_distance < target_distance_upper_lim:
		var travel_area_length = target_distance_upper_lim - target_distance_lower_lim
		var travel_center = target_distance_lower_lim + (travel_area_length / 2.0)
		var travel_factor = (travel_center - target_distance) / (travel_area_length / 2.0)
		
		travel = camera_targetting_travel * travel_factor
	
	elif target_distance >= target_distance_upper_lim:
		travel = -camera_targetting_travel
	
	##Apply travel offset
	Camera_Position_Target.transform.origin += travel
	
	transform = Camera_Position_Target.global_transform
	
	return transform


func center_camera():
	var target_direction = Vector3()
	var target_angle = Vector2()
	var facing_angle = Vector2()
	var centering_angle = Vector2()
	
	#Centering time left is 0 when centered
	if centering_time_left <= 0:
		centered = true
	
	if targetting:
		#Get values for would be focus angle to check it
		var test_focus_angle = Vector2()
		facing_direction = get_node_direction(Player.get_node("Rig"))
		target_direction = Camera_Rig.global_transform.origin.direction_to(focus_object.global_transform.origin)
		
		facing_angle.x = calculate_local_x_rotation(facing_direction)
		target_angle.x = calculate_local_x_rotation(target_direction)
		
		###Calculate would be focus angle
		##X focus angle correction
		test_focus_angle.x = target_angle.x - facing_angle.x
		test_focus_angle.x = bound_angle(test_focus_angle.x)
		
		#Check if would be focus angle is outside the focus angle limit
		if test_focus_angle.x > focus_angle_lim.x or test_focus_angle.x < -focus_angle_lim.x:
			targetting = false
			reset_recenter()
			reset_interpolate()
			emit_signal("break_target")
			return
		
		#Determine y direction for focus to rotate to (Body or Target direction)
		target_direction = Camera_Rig.global_transform.origin.direction_to(focus_object.global_transform.origin)
		centering_angle.y = calculate_global_y_rotation(target_direction)
	else:
		centering_angle.y = Player.get_node("Rig").global_transform.basis.get_rotation_quat().get_euler().y
	
	##Y angle to target calculation
	current_camera_angle.y = Camera_Rig.global_transform.basis.get_rotation_quat().get_euler().y
	
	###Y Centering
	if !centered:
		#Calculate y rotation angle before dividing it for centering
		rotate_angle.y = (centering_angle.y - current_camera_angle.y)
		rotate_angle.y = bound_angle(rotate_angle.y)
		
		rotate_angle.y = rotate_angle.y/centering_time_left
			
		###Y Rotation
		focus_angle.y -= focus_angle.y/ centering_time_left
		Camera_Rig.rotate_y(rotate_angle.y)
	else:
		focus_angle.y = focus_starting_angle.y
		#Just move to facing angle if center point reached
		rotate_angle.y = (centering_angle.y - current_camera_angle.y)
		Camera_Rig.rotate_y(rotate_angle.y)
	
	
	#Determine x direction for focus to rotate to (Body or Target direction)
	if targetting:
		target_direction = Pivot.global_transform.origin.direction_to(focus_object.global_transform.origin)
		centering_angle.x = calculate_local_x_rotation(target_direction)
	else:
		centering_angle.x = Player.get_node("Rig").global_transform.basis.get_rotation_quat().get_euler().x + focus_starting_angle.x
	
	##X angle to target calculation
	current_camera_angle.x = Pivot.global_transform.basis.get_rotation_quat().get_euler().x
	
	###X Centering
	if !centered:
		#Calculate x rotation angle before dividing it for centering
		rotate_angle.x = (centering_angle.x - current_camera_angle.x)
		#Looking down at greater than focus_angle_lim.x
		if (rotate_angle.x > focus_angle_lim.x):
			rotate_angle.x = rotate_angle.x - deg2rad(360)
		##Looking up at greater than =-focus_angle_lim.x
		if (rotate_angle.x < -focus_angle_lim.x):
			rotate_angle.x = rotate_angle.x + deg2rad(360)
			
		rotate_angle.x = rotate_angle.x/centering_time_left
			
		###X Rotation
		focus_angle.x -= focus_angle.x/centering_time_left
		Pivot.rotate_x(rotate_angle.x)
	
	else:
		focus_angle.x = focus_starting_angle.x
		#Just move to facing angle if center point reached
		rotate_angle.x = (centering_angle.x - current_camera_angle.x)
		Pivot.rotate_x(rotate_angle.x)
	
	if targetting:
		#Calculate new focus angle
		facing_direction = get_node_direction(Player.get_node("Rig"))
		facing_angle.y = calculate_global_y_rotation(facing_direction)
		facing_angle.x = calculate_local_x_rotation(facing_direction)
		target_angle.y = calculate_global_y_rotation(target_direction)
		target_angle.x = calculate_local_x_rotation(target_direction)
		
		##Y focus angle correction
		focus_angle.y = target_angle.y - facing_angle.y
		focus_angle.y = bound_angle(focus_angle.y)
		
		##X focus angle correction
		focus_angle.x = target_angle.x - facing_angle.x
		focus_angle.x = bound_angle(focus_angle.x)
		
		#Check if rotated past focus_angle_lim and correct if so
		if focus_angle.y > focus_angle_lim.y or focus_angle.y < -focus_angle_lim.y:
			Camera_Rig.rotate_y(-(focus_angle.y - (focus_angle_lim.y * sign(focus_angle.y))))
			focus_angle.y -= focus_angle.y - (focus_angle_lim.y * sign(focus_angle.y))
			targetting = false
			reset_recenter()
			reset_interpolate()
			emit_signal("break_target")
		if focus_angle.x > focus_angle_lim.x or focus_angle.x < -focus_angle_lim.x:
			Pivot.rotate_x(-(focus_angle.x - (focus_angle_lim.x * sign(focus_angle.x))))
			focus_angle.x -= focus_angle.x - (focus_angle_lim.x * sign(focus_angle.x))
			targetting = false
			reset_recenter()
			reset_interpolate()
			emit_signal("break_target")
	
	#Update previous facing angle and focus direction
	previous_facing_angle.y = calculate_global_y_rotation(get_node_direction(Player.get_node("Rig")))
	previous_facing_angle.x = calculate_local_x_rotation(get_node_direction(Player.get_node("Rig")))
	focus_direction = get_node_direction(Pivot)
	
	###Decrement Timer
	if centering_time_left > 0:
		centering_time_left -= 1


func initial_rotate(right_joystick_axis):
	rotate_camera(right_joystick_axis)


func move_camera_to_pivot(Camera_Position, Pivot):
	#Calculate distance from camera to default camera position
	var camera_translation = Pivot.global_transform.origin - Camera_Position.global_transform.origin
	
	#Move camera and collision to pivot
	Camera_Position.global_translate(camera_translation)


func camera_collision_correction(Camera_Position, Pivot, Default_Pos_Node):
	#Moves camera to pivot point
	move_camera_to_pivot(Camera_Position, Pivot)
	
	#Calculate distance from camera to default camera position
	var camera_slide_vector = Default_Pos_Node.global_transform.origin - Camera_Position.global_transform.origin
	
	#Test for collision behind camera
	var collision = Camera_Position.move_and_collide(camera_slide_vector, true, true, true)
	
	if collision:
		#Check if camera would move past pivot point
		camera_slide_vector = collision.travel

		#Move camera to collision point
		Camera_Position.global_translate(camera_slide_vector)
		is_obscured = true
	else:
		#Move camera to default position
		Camera_Position.global_translate(camera_slide_vector)
		is_obscured = false
		
	#Update focus direction
	focus_direction = get_node_direction(Pivot)
		
	collision = null


#Moves camera default position and camera to transform_final
#0 interp time is instant translation to transform final
func interpolate_camera_default_pos(transform_final, interp_time_left):
	#Camera Movement Limiting (based on centering time left)
	var move = transform_final.origin - Camera_Position_Default.global_transform.origin
	var rotate = Vector3()
	var move_factor = 1.0
	
	#Limit movement if interpolation time left
	if interp_time_left > 0:
		#Set move factor based on centering time left(decremented by center_camera())
		move_factor = 1.0 / interp_time_left #if limiting movement, calc a factor to limit rotation too
		
	##Move Limiting
	move *= move_factor
	
	##Rotate camera with limit
	#Y Rotate
	rotate = transform_final.basis.get_rotation_quat().get_euler() - Camera_Position_Default.global_transform.basis.get_rotation_quat().get_euler()
	rotate.y = bound_angle(rotate.y) * move_factor
	Camera_Position_Default.global_transform.rotated(Vector3(0,1,0), rotate.y)
	Camera_Position.global_transform.rotated(Vector3(0,1,0), rotate.y)
	
	var y_angle = transform_final.basis.get_rotation_quat().get_euler().y
	
	#X Rotate
	rotate = transform_final.basis.get_rotation_quat().get_euler() - Camera_Position_Default.global_transform.basis.get_rotation_quat().get_euler()
	if y_angle >= PI/2.0 or y_angle <= -PI/2.0:
		rotate.x = -bound_angle(rotate.x) * move_factor
	else:
		rotate.x = bound_angle(rotate.x) * move_factor
	Camera_Position_Default.global_transform.rotated(Vector3(1,0,0), rotate.x)
	Camera_Position.global_transform.rotated(Vector3(1,0,0), rotate.x)

	#Z Rotate
	rotate = transform_final.basis.get_rotation_quat().get_euler() - Camera_Position_Default.global_transform.basis.get_rotation_quat().get_euler()
	if y_angle >= PI/2.0 or y_angle <= -PI/2.0:
		rotate.z = -bound_angle(rotate.z) * move_factor
	else:
		rotate.z = bound_angle(rotate.z) * move_factor
	Camera_Position_Default.global_transform.rotated(Vector3(0,0,1), rotate.z)
	Camera_Position.global_transform.rotated(Vector3(0,0,1), rotate.z)
	
	#Move default camera position, then move camera position
	Camera_Position.global_transform.origin += move
	Camera_Position_Default.global_transform.origin += move
	
	if interpolation_time_left > 0:
		interpolation_time_left -= 1

