extends Spatial

signal head_moved(head_transform)
signal head_direction_changed(direction)
signal view_locked(is_view_locked, centering_time_left)


#Node Storage
onready var head = $Pivot

#AI Input Variables
var input = {}

###Head Variables
var head_angle = 0 			#stores head up/down rotation
var head_starting_angle = 0
var head_angle_lim = 74
var head_location
var head_rotation = Vector2()
var focus_object
var focus_location
var focus_direction
var correction_distance = 1

#Mouse Variables
var mouse_sensitivity = 0.3
var mouse_change = Vector2()

#Character Look Variables
var look_direction = Vector2() #Left, Right, Up, Down
var look_sensitivity = 3

#Centering Variables
var centering_turn_radius = deg2rad(25)
var centering_time = 6 #in frames
var centering_time_left
var facing_angle_x
var head_angle_x
var rotate_angle_x
var facing_angle_y
var head_angle_y
var rotate_angle_y
var focus_object_position

#Targetting Variables
var is_targetting = false

#Head Flags
var is_obscured
var centered = false
var centering = false
var view_locked = false


func _ready():
	look_direction.y = head_starting_angle
	rotate_head(look_direction)
	look_direction.y = 0
	
	
	#Initial values for displays/targetting
	head_location = head.get_global_transform().origin
	focus_direction = get_node_direction(head)
	
	emit_signal("head_moved", head.get_global_transform())
	emit_signal("head_direction_changed", focus_direction)


func _process(delta):
	look()


func _input(event):
	if is_ai_action_pressed("center_view", input):
		view_locked = true
		if centering == false:
			centering_time_left = centering_time
		centering = true
		emit_signal("view_locked", view_locked, centering_time_left)
	else:
		view_locked = false
		reset_recenter()
		centering = false
		emit_signal("view_locked", view_locked, centering_time_left)

	if is_ai_action_pressed("lock_target", input) and centering == true:
		reset_recenter()


func look():
	if !centering:
		rotate_head(look_direction)
	else:
		center_head()

	focus_location = head.get_global_transform().origin
	focus_direction = get_node_direction(head)
	
	emit_signal("head_moved", head.get_global_transform())
	emit_signal("head_direction_changed", focus_direction)


func rotate_head(look_change):
	if look_change.length() > 0:
		self.rotate_y(deg2rad(-look_change.x))
		
		var angle_change = look_change.y
		if head_angle + angle_change < head_angle_lim and head_angle + angle_change > -head_angle_lim:
			$Pivot.rotate_x(deg2rad(angle_change))
			head_angle += angle_change


func center_head():
	var target_direction
	
	if centering_time_left <= 0:
		head_angle = head_starting_angle
		centered = true
	
	###Set y facing angle based on direction to target
	if is_targetting:
		target_direction = self.get_global_transform().origin.direction_to(focus_object.get_global_transform().origin)
		facing_angle_y = calculate_global_y_rotation(target_direction)
	else:
		facing_angle_y = owner.get_node("Rig").get_global_transform().basis.get_euler().y
	##Y angle to target calculation
	head_angle_y = self.get_global_transform().basis.get_euler().y
	
	###Y Centering
	if !centered:
		###Left/Right Re-Centering
		if centering_time_left == centering_time:
			#Calculate y rotation angle before dividing it for centering
			rotate_angle_y = (facing_angle_y - head_angle_y)
			#Turning left at degrees > 180
			if (rotate_angle_y > deg2rad(180)):
				rotate_angle_y = rotate_angle_y - deg2rad(360)
			#Turning right at degrees < -180
			if (rotate_angle_y < deg2rad(-180)):
				rotate_angle_y = rotate_angle_y + deg2rad(360)
			
			rotate_angle_y = rotate_angle_y/centering_time
		
		###Y Rotation
		self.rotate_y(rotate_angle_y)
	else:
		#Just move to facing angle if center point reached
		rotate_angle_y = (facing_angle_y - head_angle_y)
		self.rotate_y(rotate_angle_y)
		
	###Set x facing angle based on direction to target
	if is_targetting:
		target_direction = $Pivot.get_global_transform().origin.direction_to(focus_object.get_global_transform().origin)
		facing_angle_x = calculate_local_x_rotation(target_direction) + deg2rad(head_starting_angle)
	else:
		facing_angle_x = owner.get_node("Rig").get_global_transform().basis.get_euler().x + deg2rad(head_starting_angle)
	##X angle to target calculation
	head_angle_x = $Pivot.get_global_transform().basis.get_euler().x
	
	###X Centering
	if !centered:
		###Up/Down Re-Centering
		if centering_time_left == centering_time:
			#Calculate x rotation angle before dividing it for centering
			rotate_angle_x = (facing_angle_x - head_angle_x)
			#Looking down at greater than head_angle_lim
			if (rotate_angle_x > deg2rad(head_angle_lim)):
				rotate_angle_x = rotate_angle_x - deg2rad(360)
			##Looking up at greater than =-head_angle_lim
			if (rotate_angle_x < deg2rad(-head_angle_lim)):
				rotate_angle_x = rotate_angle_x + deg2rad(360)
				
			rotate_angle_x = rotate_angle_x/centering_time
		
		###X Rotation
		$Pivot.rotate_x(rotate_angle_x)
	else:
		#Just move to facing angle if center point reached
		rotate_angle_x = (facing_angle_x - head_angle_x)
		$Pivot.rotate_x(rotate_angle_x)
		
	###Decrement Timer
	centering_time_left -= 1

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



func get_look_direction():
	return


func reset_recenter():
	centered = false
	centering_time_left = centering_time


func is_ai_action_pressed(action, input_dic):
	for input_name in input_dic:
		if typeof(input_dic[input_name]) == typeof(action):
			if input[input_name] == action:
				return true
	
	return false


func _on_Character_ai_input_changed(inputs):
	input = inputs


func _on_Character_focus_target(target_pos_node):
	if target_pos_node:
		focus_object = target_pos_node
		is_targetting = true
	else:
		focus_object = target_pos_node
		is_targetting = false
		reset_recenter()

