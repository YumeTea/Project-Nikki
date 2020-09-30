extends "res://scenes/Player/player_states/move/in_air/in_air.gd"


#Jump Variables
var jump_strength = 20
var slope_influence = 1.1

#Jump Flags
var has_jumped = false


func initialize(init_values_dic):
	for value in init_values_dic:
		self[value] = init_values_dic[value]


#Initializes state, changes animation, etc
func enter():
	snap_vector = Vector3(0,0,0)
	is_falling = false
	has_jumped = false
	connect_player_signals()
	
	if owner.get_node("AnimationTree").get("parameters/StateMachineMove/playback").is_playing() == false:
		owner.get_node("AnimationTree").get("parameters/StateMachineMove/playback").start("Jump")
	else:
		owner.get_node("AnimationTree").get("parameters/StateMachineMove/playback").travel("Jump")
	.enter()


#Cleans up state, reinitializes values like timers
func exit():
	disconnect_player_signals()
	
	.exit()


#Creates output based on the input event passed in
func handle_input(event):
	.handle_input(event)


#Acts as the _process method would
func update(delta):
	if has_jumped:
		aerial_move(delta)
	else:
		velocity.y = weight * gravity * delta
	.update(delta)
	
	if owner.is_on_floor() and has_jumped:
		emit_signal("finished", "previous")
	elif !owner.is_on_floor() and velocity.y < 0 and has_jumped:
		emit_signal("finished", "fall")


func on_animation_started(_anim_name):
	return


func on_animation_finished(_anim_name):
	return


func aerial_move(delta):
	direction = get_input_direction()
	
	calculate_aerial_velocity(delta)


func jump():
	if !has_jumped:
		speed = speed_aerial
		velocity += jump_velocity(Rig.get_node("Raycast_Floor").get_collision_normal())
		has_jumped = true


func jump_velocity(surface_normal):
	var cross
	var dot
	
	# take the cross product and dot product
	if surface_normal != Vector3.UP:
		cross = surface_normal.cross(Vector3.UP).normalized()
		dot = surface_normal.dot(Vector3.UP)
		
		var angle = (surface_normal.angle_to(Vector3.UP) / slope_influence)
		print(rad2deg(angle))
		
		#rotate wall normal towards y axis
		var surface_normal_rotated_up = surface_normal.rotated(cross, angle)
	
		var v = surface_normal_rotated_up * jump_strength
		return v
	else:
		var v = Vector3.UP * jump_strength
		return v
	










