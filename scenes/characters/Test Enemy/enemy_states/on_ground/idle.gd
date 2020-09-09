extends "res://scenes/characters/Test Enemy/enemy_states/on_ground/on_ground.gd"


func initialize(init_values_dic):
	for value in init_values_dic:
		self[value] = init_values_dic[value]


#Initializes state, changes animation, etc
func enter():
	#Send initial value for facing direction
	emit_signal("facing_direction_changed", get_node_direction(owner.get_node("Rig")))
	direction = Vector3(0,0,0)
	left_joystick_axis = Vector2(0,0)
	is_walking = false
	is_falling = false
	connect_enemy_signals()
#	owner.get_node("AnimationPlayer").play("Idle")


#Cleans up state, reinitializes values like timers
func exit():
	disconnect_enemy_signals()
#	owner.get_node("AnimationPlayer").stop()


#Creates output based on the input event passed in
func handle_input(event):
	.handle_input(event)


func handle_ai_input(input):
	if get_move_direction(input) != Vector2(0,0):
		emit_signal("finished", "walk") #emit the finished signal and input walk as next state (from state.gd)
	.handle_ai_input(input)


#Acts as the _process method would
func update(delta):
	calculate_movement_velocity(delta)
	if movement_locked:
		rotate_to_target()
	.update(delta)

func on_animation_finished(_anim_name):
	pass


func rotate_to_target():
	facing_angle = owner.get_node("Rig").get_global_transform().basis.get_euler().y
	
	if centering_time_left <= 0:
		centered = true
	
	
	if focus_target_pos != null:
		var target_position = focus_target_pos.get_global_transform().origin
		var target_angle = calculate_global_y_rotation(owner.get_global_transform().origin.direction_to(target_position))
	
		if !centered:
			turn_angle = target_angle - facing_angle
			#Turning left at degrees > 180
			if (turn_angle > deg2rad(180)):
				turn_angle = turn_angle - deg2rad(360)
			#Turning right at degrees < -180
			if (turn_angle < deg2rad(-180)):
				turn_angle = turn_angle + deg2rad(360)
			turn_angle = turn_angle/centering_time_left
		else:
			turn_angle = target_angle - facing_angle
	else:
		turn_angle = 0
	
	emit_signal("center_view", turn_angle)
	
	owner.get_node("Rig").rotate_y(turn_angle)
	
	
	###Decrement Timer
	if centering_time_left > 0:
		centering_time_left -= 1
	
	#Send signal for facing direction changed
	emit_signal("facing_direction_changed", get_node_direction(owner.get_node("Rig")))

