extends "res://scenes/Player/player_states/move/motion.gd"


"""
Issues moving through tight concave corners
"""

#Node Storage
onready var Raycast_Wall = Ledge_Grab_System.get_node("Area/Raycast_Wall")
onready var Raycast_Ledge = Ledge_Grab_System.get_node("Area/Raycast_Ledge")
onready var Raycast_Facing_Wall = Ledge_Grab_System.get_node("Raycast_Facing_Wall")
onready var Raycast_Facing_Ledge = Ledge_Grab_System.get_node("Raycast_Facing_Ledge")
onready var Raycast_Ceiling = Ledge_Grab_System.get_node("Raycast_Ceiling")

#Translate Variables
var ledge_grab_transform_init : Transform
var wall_normal_init : Vector3

#Translate Frame Timer Variables
const translate_time = 10
var translate_time_left = 0

#Ledge Hang Variables
var ledge_move_speed = 2.0
var turn_radius_ledge = deg2rad(5)
var ledge_hang_position_offset = Vector3(0.0,0.0,0.1)

#Ledge Hang bools
var on_ledge : bool
var at_ledge : bool


func initialize(init_values_dic):
	for value in init_values_dic:
		self[value] = init_values_dic[value]


#Initializes state, changes animation, etc
func enter():
	on_ledge = false
	at_ledge = false
	#Initial Translation Assignments
	ledge_grab_transform_init = ledge_grab_transform
	wall_normal_init = wall_normal
	translate_time_left = translate_time
	#Initial Physics Values
	velocity = Vector3(0,0,0)
	speed = ledge_move_speed
	
	connect_player_signals()
	
	if owner.get_node("AnimationTree").get("parameters/StateMachineMove/playback").is_playing() == false:
		owner.get_node("AnimationTree").get("parameters/StateMachineMove/playback").start("Ledge_Hang")
	else:
		owner.get_node("AnimationTree").get("parameters/StateMachineMove/playback").travel("Ledge_Hang")
	.enter()


#Cleans up state, reinitializes values like timers
func exit():
	speed = speed_default
	Ledge_Grab_System.get_node("Timer").start(0.267)
	
	disconnect_player_signals()
	
	.exit()


#Creates output based on the input event passed in
func handle_input(event):
	direction = get_input_direction()
	facing_direction = get_node_direction(Rig)
	var facing_dot_direction = facing_direction.dot(direction)
	
	if event.is_action_pressed("jump") and event.get_device() == 0:
		if facing_dot_direction < -0.333:
			emit_signal("finished", "fall")
		elif at_ledge:
			emit_signal("finished", "ledge_climb")
	.handle_input(event)


#Acts as the _process method would
func update(delta):
	if !on_ledge:
		translate_to_ledge(ledge_grab_transform, wall_normal)
	elif on_ledge:
		ledge_move(delta)
		
		rotate_to_ledge()
		adjust_hang_height()
		
		if at_ledge and (!Raycast_Facing_Wall.is_colliding() or !Raycast_Facing_Ledge.is_colliding()):
			print(!Raycast_Facing_Wall.is_colliding())
			print(!Raycast_Facing_Ledge.is_colliding())
			print("Racast_Facing_Wall lost contact")
			emit_signal("finished", "fall")
	
	.update(delta)


func on_animation_started(_anim_name):
	return


func on_animation_finished(_anim_name):
	return


func ledge_move(delta):
	direction = get_input_direction()
	var wall_facing_angle_global = calculate_global_y_rotation(-Raycast_Facing_Wall.get_collision_normal())
	var input_direction_angle
	
	#Calc angle of input relative to player facing direction
	input_direction_angle = calculate_global_y_rotation(direction) - wall_facing_angle_global
	
	#Get pure left/right input amount
	var direction_horizontal = Vector3(0,0,direction.length()).rotated(Vector3.UP, input_direction_angle)
	direction_horizontal = direction_horizontal.x
	
	#Align direction to left/right of player rig facing angle
	direction = Vector3(0,0,direction_horizontal).rotated(Vector3.UP, wall_facing_angle_global + (PI / 2.0))
	
	velocity = calculate_ledge_velocity(delta)


#Will need to account for changes in grab point height as well
func rotate_to_ledge():
	var wall_facing_angle_global = calculate_global_y_rotation(-Raycast_Facing_Wall.get_collision_normal())
	facing_angle.y = Rig.global_transform.basis.get_euler().y
	
	turn_angle.y = wall_facing_angle_global - facing_angle.y
	turn_angle.y = bound_angle(turn_angle.y)
	
	if (!is_equal_approx(turn_angle.y, 0.0) and turn_angle.y <= deg2rad(90) and turn_angle.y >= deg2rad(-90)):
		print("wall_facing_angle:    " + str(rad2deg(wall_facing_angle_global)))
		print("current_facing_angle: " + str(rad2deg(facing_angle.y)))
		if at_ledge:
			at_ledge = false #false while rotating to ledge; can't climb up
			
			#Rotate movement velocity to be parallel to wall
			velocity = velocity.rotated(Vector3.UP, turn_angle.y)
		
		#Rotate player around wall raycast collision point
		var angle = clamp(turn_angle.y, -turn_radius_ledge, turn_radius_ledge)
		var rotation_point = Raycast_Facing_Wall.get_collision_point()
		
		var transform = Player.global_transform
		transform.origin -= rotation_point
		transform = transform.rotated(Vector3.UP, angle)
		transform.origin += rotation_point
		
		Player.global_transform.origin = transform.origin
		Rig.rotate_y(angle)
		
		if angle == turn_angle.y:
			ledge_hang_height = ledge_grab_transform.origin.y - Ledge_Grab_System.default_offset
			wall_normal = Raycast_Facing_Wall.get_collision_normal()
			wall_normal.y = 0.0
			wall_normal = wall_normal.normalized()
		
			owner.global_transform.origin.x = ledge_grab_transform.origin.x
			owner.global_transform.origin.y = ledge_hang_height
			owner.global_transform.origin.z = ledge_grab_transform.origin.z
			owner.global_transform.origin += (wall_normal * (Player_Collision.shape.radius + ledge_hang_position_offset.z))
	else:
		at_ledge = true #check this in same frame??


func adjust_hang_height():
	ledge_hang_height = ledge_grab_transform.origin.y - Ledge_Grab_System.default_offset
	owner.global_transform.origin.y = ledge_hang_height


#Moves player to ledge hang position on entering ledge_hang state
func translate_to_ledge(ledge_grab_transform, wall_normal):
	if translate_time_left > 0:
		###Translate Character Object to Ledge
		ledge_hang_height = ledge_grab_transform.origin.y - Ledge_Grab_System.default_offset
		
		#Modify grab point transform to account for player collision size
		ledge_grab_transform.origin.y = ledge_hang_height
		wall_normal = Vector3(wall_normal.x, 0.0, wall_normal.z).normalized()
		ledge_grab_transform.origin += wall_normal * (Player_Collision.shape.radius + ledge_hang_position_offset.z)
		
		var distance = ledge_grab_transform.origin - Player.global_transform.origin
		distance /= translate_time_left
		
		#Move Player to grab point origin
		Player.global_transform.origin += distance
		
		###Center Character Rig
		var wall_face_angle : Vector3
		wall_face_angle.y = calculate_global_y_rotation(-wall_normal) #this normal was made horizontal abouve
		facing_angle.y = calculate_global_y_rotation(get_node_direction(Player.get_node("Rig")))
		
		turn_angle.y = wall_face_angle.y - facing_angle.y
		turn_angle.y = bound_angle(turn_angle.y)
		turn_angle.y /= translate_time_left
		
		Rig.rotate_y(turn_angle.y)
		
		#Decrement Frame Timer
		translate_time_left -= 1
	
	if translate_time_left <= 0:
		on_ledge = true
		at_ledge = true


