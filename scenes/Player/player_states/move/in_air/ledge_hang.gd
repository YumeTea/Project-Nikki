extends "res://scenes/Player/player_states/move/motion.gd"


onready var Raycast_Wall = Ledge_Grab_System.get_node("Area/Raycast_Wall")
onready var Raycast_Ledge = Ledge_Grab_System.get_node("Area/Raycast_Ledge")
onready var Raycast_Facing_Wall = Ledge_Grab_System.get_node("Raycast_Facing_Wall")
onready var Raycast_Facing_Ledge = Ledge_Grab_System.get_node("Raycast_Facing_Ledge")
onready var Raycast_Ceiling = Ledge_Grab_System.get_node("Raycast_Ceiling")


var ledge_move_speed = 2.0
var ledge_hang_position_offset = Vector3(0,0,0.1)


func initialize(init_values_dic):
	for value in init_values_dic:
		self[value] = init_values_dic[value]


#Initializes state, changes animation, etc
func enter():
	velocity = Vector3(0,0,0)
	speed = ledge_move_speed
	
	#Translate player to ledge
	translate_to_ledge()
	
	connect_player_signals()
	
	if owner.get_node("AnimationTree").get("parameters/StateMachineMove/playback").is_playing() == false:
		owner.get_node("AnimationTree").get("parameters/StateMachineMove/playback").start("Ledge_Hang")
	else:
		owner.get_node("AnimationTree").get("parameters/StateMachineMove/playback").travel("Ledge_Hang")
	.enter()


#Cleans up state, reinitializes values like timers
func exit():
	speed = speed_default
	Ledge_Grab_System.get_node("Timer").start(0.134)
	
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
		else:
			emit_signal("finished", "ledge_climb")
	.handle_input(event)


#Acts as the _process method would
func update(delta):
	ledge_move(delta)
	.update(delta)
	
	rotate_to_ledge(delta)
	
	if !Raycast_Facing_Wall.is_colliding():
		print("Racast_Facing_Wall lost contact")
		emit_signal("finished", "fall")


func on_animation_finished(_anim_name):
	return


func ledge_move(delta):
	direction = get_input_direction()
	facing_angle.y = Rig.global_transform.basis.get_euler().y
	var input_direction_angle
	
	#Calc angle of input relative to player facing direction
	input_direction_angle = calculate_global_y_rotation(direction) - facing_angle.y
	
	#Get pure left/right input amount
	var direction_horizontal = Vector3(0,0,direction.length()).rotated(Vector3(0,1,0), input_direction_angle)
	direction_horizontal = direction_horizontal.x
	
	#Align direction to left/right of player rig facing angle
	direction = Vector3(0,0,direction_horizontal).rotated(Vector3(0,1,0), facing_angle.y + (PI / 2.0))
	
	calculate_ledge_velocity(delta)


func rotate_to_ledge(delta):
	var wall_facing_angle_global = calculate_global_y_rotation(-Raycast_Facing_Wall.get_collision_normal())
	facing_angle.y = Rig.global_transform.basis.get_euler().y
	
	turn_angle.y = wall_facing_angle_global - facing_angle.y
	turn_angle.y = bound_angle(turn_angle.y)
	
	velocity = velocity.rotated(Vector3(0,1,0), turn_angle.y)
	
	if !is_equal_approx(turn_angle.y, 0.0):
		Rig.rotate_y(turn_angle.y)
		velocity.rotated(Vector3(0,1,0), turn_angle.y)
		
		#Translate player to grab position
		var wall_normal_horizontal = -Raycast_Facing_Wall.get_collision_normal()
		wall_normal_horizontal = Vector3(wall_normal_horizontal.x, 0.0, wall_normal_horizontal.z).normalized()
		
		owner.global_transform.origin.x = ledge_grab_transform.origin.x
		owner.global_transform.origin.z = ledge_grab_transform.origin.z
		owner.global_transform.origin += (Raycast_Facing_Wall.get_collision_normal() * (Player_Collision.shape.radius + ledge_hang_position_offset.z))
		
	
	Raycast_Ledge.force_raycast_update()
	Raycast_Facing_Ledge.force_raycast_update()


#Currently does not interpolate, just snaps player to ledge
#Moves player to ledge hang position on entering ledge_hang state
func translate_to_ledge():
	###Translate Character Object to Ledge
	ledge_hang_height = ledge_height - Ledge_Grab_System.default_offset
	
	#Modify grab point transform to account for player collision size
	ledge_grab_transform.origin.y = ledge_hang_height
	wall_normal = Vector3(wall_normal.x, 0.0, wall_normal.z).normalized()
	ledge_grab_transform.origin += wall_normal * (Player_Collision.shape.radius + ledge_hang_position_offset.z)
	
	Player.global_transform.origin = ledge_grab_transform.origin
	
	###Center Character Rig
	var wall_face_angle : Vector3
	wall_face_angle.y = calculate_global_y_rotation(-wall_normal) #this normal was made horizontal abouve
	facing_angle.y = calculate_global_y_rotation(get_node_direction(Player.get_node("Rig")))
	
	turn_angle.y = wall_face_angle.y - facing_angle.y
	turn_angle.y = bound_angle(turn_angle.y)
	
	Rig.rotate_y(turn_angle.y)





