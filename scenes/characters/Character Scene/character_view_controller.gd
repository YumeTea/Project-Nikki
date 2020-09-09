extends Spatial


signal head_moved(head_transform)
signal focus_direction_changed(direction)
signal view_locked(is_view_locked, centering_time_left)
signal view_blocked(is_obscured)

signal break_target

#Node Storage
onready var head = $Pivot

#AI Input Variables
var input = {}

###Head Variables
var focus_angle = Vector2() #stores local angle of pivot
var focus_angle_global = Vector2()
var focus_starting_angle = Vector2(deg2rad(0), deg2rad(0))
var focus_angle_lim = Vector2(deg2rad(74), deg2rad(82))
var head_position
var head_rotation = Vector2()
var focus_object
var focus_location
var focus_direction
var correction_distance = 1

#Character Look Variables
var right_joystick_axis = Vector2()
var look_direction = Vector2() #Left, Right, Up, Down
var look_sensitivity = 3

#Centering Variables
var centering_turn_radius = deg2rad(25)
var centering_time = 6 #in frames
var centering_time_left = centering_time
var current_camera_angle = Vector2()
var rotate_angle = Vector2()
var focus_object_position

#Targetting Variables
var is_targetting = false

#Head Flags
var is_obscured
var centered = false
var centering = false
var view_locked = false

#Body Variables
var facing_direction = Vector3()
var previous_facing_angle = Vector2()
var body_turn_angle = Vector2()


func _ready():
	#Initial facing direction used by rotate_head
	previous_facing_angle.y = calculate_global_y_rotation(get_node_direction(owner.get_node("Rig")))
	previous_facing_angle.x = calculate_local_x_rotation(get_node_direction(owner.get_node("Rig")))
	
	###Head Value Initialization
	rotate_head(Vector2(rad2deg(focus_starting_angle.y), rad2deg(focus_starting_angle.x)))
	focus_angle = focus_starting_angle
	
	#Initial values for displays/targetting
	head_position = head.get_global_transform().origin
	focus_direction = get_node_direction(head)
	
	emit_signal("head_moved", head.get_global_transform())
	emit_signal("focus_direction_changed", focus_direction)


func _ai_input(input):
	get_right_joystick_input(input)
	if is_ai_action_pressed("center_view", input):
		view_locked = true
		centering = true
		if is_ai_action_pressed("center_view", input):
			centered = false
			reset_recenter()
		emit_signal("view_locked", view_locked, centering_time_left)
	if is_ai_action_released("center_view", input):
		view_locked = false
		centering = false
		emit_signal("view_locked", view_locked, centering_time_left)
	
	if is_ai_action_just_pressed("lock_target", input):
		reset_recenter()


func _process(_delta):
	#Process AI input
	_ai_input(input)
	
	look()


func look():
	if right_joystick_axis != null:
		if !centering and !is_targetting:
			rotate_head(right_joystick_axis)
		else:
			center_head()

#	camera_collision_correction(camera, pivot, default_camera_position, camera_collision)
	
	previous_facing_angle.y = calculate_global_y_rotation(get_node_direction(owner.get_node("Rig")))
	previous_facing_angle.x = calculate_local_x_rotation(get_node_direction(owner.get_node("Rig")))
	
	#Tell free camera if default view is obscured
	if is_obscured:
		emit_signal("view_blocked", is_obscured)
	#Tell free camera that camera position has moved
	emit_signal("head_moved", head.get_global_transform())
	emit_signal("focus_direction_changed", focus_direction)


func rotate_head(input_change):
	
	var focus_angle_change = Vector2(0,0)
	var turn_angle = Vector2()
	facing_direction = get_node_direction(owner.get_node("Rig"))
	var facing_angle = Vector2()
	
	focus_direction = get_node_direction($Pivot)
	focus_angle_global.y = calculate_global_y_rotation(focus_direction)
	focus_angle_global.x = calculate_local_x_rotation(focus_direction)
	facing_angle.y = calculate_global_y_rotation(facing_direction)
	facing_angle.x = calculate_local_x_rotation(facing_direction)
	
	var facing_angle_change = Vector2()
	###Y Focus Angle Limiting
	facing_angle_change.y = previous_facing_angle.y - facing_angle.y
	#Turning left at degrees > 180
	if (facing_angle_change.y > deg2rad(180)):
		facing_angle_change.y = facing_angle_change.y - deg2rad(360)
	#Turning right at degrees < -180
	if (facing_angle_change.y < deg2rad(-180)):
		facing_angle_change.y = facing_angle_change.y + deg2rad(360)
		
	if(focus_angle.y + facing_angle_change.y) < focus_angle_lim.y and (focus_angle.y + facing_angle_change.y) > -focus_angle_lim.y:
		focus_angle.y += facing_angle_change.y
	else:
		focus_angle_change.y = (sign(focus_angle.y) * focus_angle_lim.y) - focus_angle.y
		focus_angle.y += focus_angle_change.y
		turn_angle.y = -facing_angle_change.y + focus_angle_change.y
			
		self.rotate_y(turn_angle.y)
	
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
			
		$Pivot.rotate_y(turn_angle.x)
	
	###Focus Input Handling
	if input_change.length() > 0:
		var angle_change = Vector2()
		
		angle_change.y = deg2rad(-input_change.x)
		if focus_angle.y + angle_change.y < focus_angle_lim.y and focus_angle.y + angle_change.y > -focus_angle_lim.y:
			self.rotate_y(deg2rad(-input_change.x))
			focus_angle.y += angle_change.y
		else:
			self.rotate_y((focus_angle_lim.y * sign(focus_angle.y)) - focus_angle.y)
			focus_angle.y += ((focus_angle_lim.y * sign(focus_angle.y)) - focus_angle.y)

		angle_change.x = deg2rad(input_change.y)
		if focus_angle.x + angle_change.x < focus_angle_lim.x and focus_angle.x + angle_change.x > -focus_angle_lim.x:
			$Pivot.rotate_x(deg2rad(input_change.y))
			focus_angle.x += angle_change.x
		else:
			$Pivot.rotate_x((focus_angle_lim.x * sign(focus_angle.x)) - focus_angle.x)
			focus_angle.x += ((focus_angle_lim.x * sign(focus_angle.x)) - focus_angle.x)

#func rotate_camera_tank_style(input_change):
#	var next_focus_angle = Vector2()
#	var turn_angle = Vector2()
#	var facing_direction = get_node_direction(owner.get_node("Rig"))
#	var facing_angle = Vector2()
#
#	#Move head with body facing direction
#	facing_angle.y = calculate_global_y_rotation(facing_direction)
#	self.rotate_y(facing_angle.y - previous_facing_angle.y)
#	facing_angle.x = calculate_local_x_rotation(facing_direction)
#	$Pivot.rotate_x(facing_angle.x)
#
#	if input_change.length() > 0:
#		var angle_change = Vector2()
#
#		angle_change.y = deg2rad(input_change.x)
#		if focus_angle.y + angle_change.y < focus_angle_lim.y and focus_angle.y + angle_change.y > -focus_angle_lim.y:
#			self.rotate_y(deg2rad(-input_change.x))
#			focus_angle.y += angle_change.y
#		else:
#			self.rotate_y((focus_angle_lim.y * sign(focus_angle.y)) - focus_angle.y)
#			focus_angle.y += ((focus_angle_lim.y * sign(focus_angle.y)) - focus_angle.y)
#
#		angle_change.x = deg2rad(input_change.y)
#		if focus_angle.x + angle_change.x < focus_angle_lim.x and focus_angle.x + angle_change.x > -focus_angle_lim.x:
#			$Pivot.rotate_x(deg2rad(input_change.y))
#			focus_angle.x += angle_change.x
#		else:
#			$Pivot.rotate_x((focus_angle_lim.x * sign(focus_angle.x)) - focus_angle.x)
#			focus_angle.x += ((focus_angle_lim.x * sign(focus_angle.x)) - focus_angle.x)
#
#	previous_facing_angle.y = calculate_global_y_rotation(facing_direction)
#	previous_facing_angle.x = calculate_local_x_rotation(facing_direction)


func center_head():
	var target_direction = Vector3()
	var target_angle = Vector2()
	var facing_angle = Vector2()
	var centering_angle = Vector2()
	body_turn_angle = Vector2()
	
	#Centering time left is 0 when centered
	if centering_time_left <= 0:
		centered = true
	
	###Set y facing angle based on direction to target
	if is_targetting:
		#Get values for would be focus angle to check it
		var test_focus_angle = Vector2()
		facing_direction = get_node_direction(owner.get_node("Rig"))
		target_direction = self.get_global_transform().origin.direction_to(focus_object.get_global_transform().origin)

		facing_angle.y = calculate_global_y_rotation(facing_direction)
		facing_angle.x = calculate_local_x_rotation(facing_direction)
		target_angle.y = calculate_global_y_rotation(target_direction)
		target_angle.x = calculate_local_x_rotation(target_direction)
		
		###Calculate would be focus angle
		##Y focus angle correction
		test_focus_angle.y = target_angle.y - facing_angle.y
		#Focus angle y > 180
		if (test_focus_angle.y > deg2rad(180)):
			test_focus_angle.y = test_focus_angle.y - deg2rad(360)
		#Focus angle y < -180
		if (test_focus_angle.y < deg2rad(-180)):
			test_focus_angle.y = test_focus_angle.y + deg2rad(360)
		
		##X focus angle correction
		test_focus_angle.x = target_angle.x - facing_angle.x
		#Focus angle x > 180
		if (test_focus_angle.x > deg2rad(180)):
			test_focus_angle.x = test_focus_angle.x - deg2rad(360)
		#Focus angle x < -180
		if (test_focus_angle.x < deg2rad(-180)):
			test_focus_angle.x = test_focus_angle.x + deg2rad(360)
		
		#Check if would be focus angle is outside the focus angle limit
		if test_focus_angle.y > focus_angle_lim.y or test_focus_angle.y < -focus_angle_lim.y:
			is_targetting = false
			reset_recenter()
			emit_signal("break_target")
			return
		if test_focus_angle.x > focus_angle_lim.x or test_focus_angle.x < -focus_angle_lim.x:
			is_targetting = false
			reset_recenter()
			emit_signal("break_target")
			return
		
		#If turning the opposite direction of body, let body rotate and center on facing angle
		body_turn_angle = get_body_centering_angle(owner.get_node("Rig"))
		if sign(body_turn_angle.y) != sign(focus_angle.y):
			self.rotate_y(body_turn_angle.y)
		
		#Determine y direction for focus to rotate to
		if !centered and centering and sign(body_turn_angle.y) != sign(focus_angle.y):
			target_direction = get_node_direction(owner.get_node("Rig"))
		else:
			target_direction = self.get_global_transform().origin.direction_to(focus_object.get_global_transform().origin)
		centering_angle.y = calculate_global_y_rotation(target_direction)
	else:
		centering_angle.y = owner.get_node("Rig").get_global_transform().basis.get_euler().y
	
	##Y angle to target calculation
	current_camera_angle.y = self.get_global_transform().basis.get_euler().y
	
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
		self.rotate_y(rotate_angle.y)
	else:
		focus_angle.y = focus_starting_angle.y
		#Just move to facing angle if center point reached
		rotate_angle.y = (centering_angle.y - current_camera_angle.y)
		self.rotate_y(rotate_angle.y)
	
	
	###Set x facing angle based on direction to target
	#Determine x direction for focus to rotate to
	if is_targetting:
		target_direction = $Pivot.get_global_transform().origin.direction_to(focus_object.get_global_transform().origin)
		centering_angle.x = calculate_local_x_rotation(target_direction) + focus_starting_angle.x
	else:
		centering_angle.x = owner.get_node("Rig").get_global_transform().basis.get_euler().x + focus_starting_angle.x
	
	##X angle to target calculation
	current_camera_angle.x = $Pivot.get_global_transform().basis.get_euler().x
	
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
		$Pivot.rotate_x(rotate_angle.x)
	
	else:
		focus_angle.x = focus_starting_angle.x
		#Just move to facing angle if center point reached
		rotate_angle.x = (centering_angle.x - current_camera_angle.x)
		$Pivot.rotate_x(rotate_angle.x)
	
	if is_targetting:
		#Calculate new focus angle
		facing_direction = get_node_direction(owner.get_node("Rig"))
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
				self.rotate_y(-(focus_angle.y - (focus_angle_lim.y * sign(focus_angle.y))))
				focus_angle.y -= focus_angle.y - (focus_angle_lim.y * sign(focus_angle.y))
				is_targetting = false
				reset_recenter()
				emit_signal("break_target")
			if focus_angle.x > focus_angle_lim.x or focus_angle.x < -focus_angle_lim.x:
				$Pivot.rotate_x(-(focus_angle.x - (focus_angle_lim.x * sign(focus_angle.x))))
				focus_angle.x -= focus_angle.x - (focus_angle_lim.x * sign(focus_angle.x))
				is_targetting = false
				reset_recenter()
				emit_signal("break_target")
	
	
	###Decrement Timer
	if centering_time_left > 0:
		centering_time_left -= 1


func get_body_centering_angle(body_node):
	var facing_angle = body_node.get_global_transform().basis.get_euler().y
	
	if is_targetting:
		var target_position = focus_object.get_global_transform().origin
		var target_angle = calculate_global_y_rotation(owner.get_global_transform().origin.direction_to(target_position))
		
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


func get_node_direction(head_node):
	var direction = Vector3(0,0,1)
	var rotate_by = head_node.get_global_transform().basis.get_euler()
	direction = direction.rotated(Vector3(1,0,0), rotate_by.x)
	direction = direction.rotated(Vector3(0,1,0), rotate_by.y)
	direction = direction.rotated(Vector3(0,0,1), rotate_by.z)
	
	return direction


func get_right_joystick_input(input):
	right_joystick_axis = input["input_current"]["right_stick"]


func reset_recenter():
	centered = false
	centering_time_left = centering_time


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


func _on_Character_ai_input_changed(inputs):
	input = inputs


func _on_Character_focus_target(target_pos_node):
	if target_pos_node:
		focus_object = target_pos_node
		is_targetting = true
		centering = true
	else:
		focus_object = target_pos_node
		is_targetting = false
		centering = false



