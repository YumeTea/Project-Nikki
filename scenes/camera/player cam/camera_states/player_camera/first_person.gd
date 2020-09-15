extends "res://scenes/camera/player cam/camera_states/player_camera/player_camera.gd"


"""
Find a better way to get and store default camera position values
"""

var pivot_pos_default_local = Vector3(0,0.8,0.3)
var camera_pos_default_local = Vector3(0.0,0.0,0.0)

var focus_starting_angle = Vector2(deg2rad(0), deg2rad(0))
var focus_angle_lim = Vector2(deg2rad(57.5), deg2rad(82))


func initialize(init_values_dic):
	for value in init_values_dic:
		self[value] = init_values_dic[value]


#Initializes state, changes animation, etc
func enter():
	view_mode = "first_person"
	view_locked = true
	
	#Initial values for rotate function
	previous_facing_angle.y = calculate_global_y_rotation(facing_direction)
	previous_facing_angle.x = calculate_local_x_rotation(facing_direction)
	
	#More initial values after initial rotation
	focus_angle.y = 0.0
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
	if event.is_action_pressed("switch_view") and event.get_device() == 0:
		view_change_time_left = view_change_time
		emit_signal("finished", "third_person")
	
	if Input.is_action_pressed("center_view"):
		strafe_locked = true
		centering = true
		if event.is_action_pressed("center_view") and event.get_device() == 0:
			centered = false
			reset_recenter()
		emit_signal("view_locked", strafe_locked, centering_time_left)
	if event.is_action_released("center_view") and event.get_device() == 0:
		strafe_locked = false
		centering = false
		emit_signal("view_locked", strafe_locked, centering_time_left)
	
#	if event.is_action_pressed("lock_target") and event.get_device() == 0:
#		reset_recenter()
	
	.handle_input(event)


#Acts as the _process method would
func update(_delta):
	if view_change_time_left > 0:
		enter_first_person()
	look_first_person()


func _on_animation_finished(_anim_name):
	return


func enter_first_person():
	Camera_Position.get_node("CollisionShape").disabled = true
	
	if view_change_time_left > 0:
		var pivot_move = (pivot_pos_default_local - Pivot.transform.origin) / view_change_time_left
		var head_target_move = ((Pivot.transform.origin + head_target_offset_default) - Head_Target.transform.origin) / view_change_time_left
		var camera_move = (camera_pos_default_local - Camera_Position.transform.origin) / view_change_time_left
		var camera_default_move = (camera_pos_default_local - Camera_Position_Default.transform.origin) / view_change_time_left
		
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


func look_first_person():
	#Move head target before moving camera
	move_head_target(focus_object)
	
	if view_locked:
		previous_facing_angle.y = calculate_global_y_rotation(get_node_direction(Pivot))
		previous_facing_angle.x = calculate_local_x_rotation(get_node_direction(Camera_Rig))
	elif centering:
		center_camera() #no camera control if centering
	else:
		rotate_camera_angle_limited(right_joystick_axis)
	
	#Move head target after moving camera
	move_head_target(focus_object)
	
	#Tell free camera if default view is obscured
	if is_obscured:
		emit_signal("view_blocked", is_obscured)
		
	#Tell free camera and other nodes that camera position has moved
	emit_signal("camera_moved", Camera_Position.global_transform)
	emit_signal("camera_direction_changed", -get_node_direction(Camera_Position))
	emit_signal("focus_direction_changed", get_node_direction(Pivot))


#Allows rotation of camera up to focus_angle_lim and adjusts for body turning (limits neck rotation)
func rotate_camera_angle_limited(input_change):
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
	##Bounding for facing_angle_change
	#Turning left at degrees > 180
	if (facing_angle_change.y > deg2rad(180)):
		facing_angle_change.y = facing_angle_change.y - deg2rad(360)
	#Turning right at degrees < -180
	if (facing_angle_change.y < deg2rad(-180)):
		facing_angle_change.y = facing_angle_change.y + deg2rad(360)
	
	#Change focus angle if body rotated
	if(focus_angle.y + facing_angle_change.y) < focus_angle_lim.y and (focus_angle.y + facing_angle_change.y) > -focus_angle_lim.y:
		focus_angle.y += facing_angle_change.y
	else: #If facing angle goes outside focus cone, rotate camera rig
		focus_angle_change.y = (sign(focus_angle.y) * focus_angle_lim.y) - focus_angle.y
		focus_angle.y += focus_angle_change.y
		turn_angle.y = -facing_angle_change.y + focus_angle_change.y
		
		Camera_Rig.rotate_y(turn_angle.y)
	
	###X Focus Angle Limiting
	facing_angle_change.x = previous_facing_angle.x - facing_angle.x
	#Turning left at degrees > 180
	if (facing_angle_change.x > deg2rad(180)):
		facing_angle_change.x = facing_angle_change.x - deg2rad(360)
	#Turning right at degrees < -180
	if (facing_angle_change.x < deg2rad(-180)):
		facing_angle_change.x = facing_angle_change.x + deg2rad(360)
		
	if(focus_angle.x + facing_angle_change.x) < focus_angle_lim.x and (focus_angle.x + facing_angle_change.x) > -focus_angle_lim.x:
		focus_angle.x += facing_angle_change.x
	else:
		focus_angle_change.x = (sign(focus_angle.x) * focus_angle_lim.x) - focus_angle.x
		focus_angle.x += focus_angle_change.x
		turn_angle.x = -facing_angle_change.x + focus_angle_change.x
			
		Pivot.rotate_y(turn_angle.x)
	
	###Focus Input Handling (Actual rotation based on input)
	if input_change.length() > 0:
		var angle_change = Vector2()
		
		angle_change.y = deg2rad(-input_change.x) * look_speed
		if focus_angle.y + angle_change.y < focus_angle_lim.y and focus_angle.y + angle_change.y > -focus_angle_lim.y:
			Camera_Rig.rotate_y(angle_change.y)
			focus_angle.y += angle_change.y
		else:
			Camera_Rig.rotate_y((focus_angle_lim.y * sign(focus_angle.y)) - focus_angle.y)
			focus_angle.y += ((focus_angle_lim.y * sign(focus_angle.y)) - focus_angle.y)
		
		angle_change.x = deg2rad(input_change.y) * look_speed
		if focus_angle.x + angle_change.x < focus_angle_lim.x and focus_angle.x + angle_change.x > -focus_angle_lim.x:
			Pivot.rotate_x(angle_change.x)
			focus_angle.x += angle_change.x
		else:
			Pivot.rotate_x((focus_angle_lim.x * sign(focus_angle.x)) - focus_angle.x)
			focus_angle.x += ((focus_angle_lim.x * sign(focus_angle.x)) - focus_angle.x)
	
	#Update previous facing angle and focus_direction
	previous_facing_angle.y = calculate_global_y_rotation(get_node_direction(Player.get_node("Rig")))
	previous_facing_angle.x = calculate_local_x_rotation(get_node_direction(Player.get_node("Rig")))
	focus_direction = get_node_direction(Pivot)


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
		#Focus angle x > 180
		if (test_focus_angle.x > deg2rad(180)):
			test_focus_angle.x = test_focus_angle.x - deg2rad(360)
		#Focus angle x < -180
		if (test_focus_angle.x < deg2rad(-180)):
			test_focus_angle.x = test_focus_angle.x + deg2rad(360)
		
		#Check if would be focus angle is outside the focus angle limit
		if test_focus_angle.x > focus_angle_lim.x or test_focus_angle.x < -focus_angle_lim.x:
			targetting = false
			reset_recenter()
			emit_signal("break_target")
			return
		
		#Determine y direction for focus to rotate to (Body or Target direction)
		target_direction = Camera_Rig.global_transform.origin.direction_to(focus_object.global_transform.origin)
		centering_angle.y = calculate_global_y_rotation(target_direction)
	else:
		centering_angle.y = calculate_global_y_rotation(focus_direction)
	
	##Y angle to target calculation
	current_camera_angle.y = Camera_Rig.global_transform.basis.get_rotation_quat().get_euler().y
	
	###Y Centering
	if !centered:
		#Calculate y rotation angle before dividing it for centering
		rotate_angle.y = (centering_angle.y - current_camera_angle.y)
		#Turning left at degrees > 180
		if (rotate_angle.y > deg2rad(180)):
			rotate_angle.y = rotate_angle.y - deg2rad(360)
		#Turning right at degrees < -180
		if (rotate_angle.y < deg2rad(-180)):
			rotate_angle.y = rotate_angle.y + deg2rad(360)
		
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
		centering_angle.x = focus_starting_angle.x
	
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
		#Focus angle y > 180
		if (focus_angle.y > deg2rad(180)):
			focus_angle.y = focus_angle.y - deg2rad(360)
		#Focus angle y < -180
		if (focus_angle.y < deg2rad(-180)):
			focus_angle.y = focus_angle.y + deg2rad(360)
		
		##X focus angle correction
		focus_angle.x = target_angle.x - facing_angle.x
		#Focus angle y > 180
		if (focus_angle.x > deg2rad(180)):
			focus_angle.x = focus_angle.x - deg2rad(360)
		#Focus angle y < -180
		if (focus_angle.x < deg2rad(-180)):
			focus_angle.x = focus_angle.x + deg2rad(360)
		
			#Check if rotated past focus_angle_lim and correct if so
			if focus_angle.y > focus_angle_lim.y or focus_angle.y < -focus_angle_lim.y:
				Camera_Rig.rotate_y(-(focus_angle.y - (focus_angle_lim.y * sign(focus_angle.y))))
				focus_angle.y -= focus_angle.y - (focus_angle_lim.y * sign(focus_angle.y))
				targetting = false
				reset_recenter()
				emit_signal("break_target")
			if focus_angle.x > focus_angle_lim.x or focus_angle.x < -focus_angle_lim.x:
				Pivot.rotate_x(-(focus_angle.x - (focus_angle_lim.x * sign(focus_angle.x))))
				focus_angle.x -= focus_angle.x - (focus_angle_lim.x * sign(focus_angle.x))
				targetting = false
				reset_recenter()
				emit_signal("break_target")
	
	#Update previous facing angle and focus direction
	previous_facing_angle.y = calculate_global_y_rotation(get_node_direction(Player.get_node("Rig")))
	previous_facing_angle.x = calculate_local_x_rotation(get_node_direction(Player.get_node("Rig")))
	focus_direction = get_node_direction(Pivot)
	
	###Decrement Timer
	if centering_time_left > 0:
		centering_time_left -= 1


func initial_rotate(right_joystick_axis):
	rotate_camera_angle_limited(right_joystick_axis)














