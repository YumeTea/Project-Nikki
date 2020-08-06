extends KinematicBody


###Physics Variables
var direction = Vector3(0,0,0)
var direction_angle = 0
var velocity = Vector3(0,0,0)
const gravity = -9.8
const weight = 5

###Camera Variables
var camera 						#stores camera node location
var camera_angle = 0 			#stores camera angle, initial assignment is starting camera angle
var mouse_sensitivity = 0.3
var camera_change = Vector2()
var camera_rotation = Vector2()

###Player Movement Variables
##Walk variables
const speed = 18
const turn_radius = 4 			#in degrees
const quick_turn_radius = 10 	#in degrees
const uturn_radius = 2 			#in degrees
#const MAX_RUNNING_SPEED = 9
const ACCEL = 6
const DEACCEL = 6
#var position
var facing_angle 				#Goes from -pi > 0 > pi
var is_walking = false
var snap_vector = Vector3() 	#Used for Move_and_slide_with_snap
var floor_contact

##Jump Variables
var jump_strength = 20

###Projectile Variables
var RIGID_PROJ = preload("res://scenes/objects/Test Objects/Projectiles/Rigid_Projectile_Test/Projectile.tscn")
var MAGIC_ORB = preload("res://scenes/objects/Test Objects/Projectiles/Magic Orb/magic_orb.tscn")
var projectile_time = 0
var projectile_count = 0

###Other Variables
var is_sky = false #for Canvas skybox

func _ready():
	camera = get_node("Head/Pivot/Camera")

func _process(_delta):
		skybox_rotation()

func _physics_process(delta):
	look()
	walk(delta)
	cast_projectile()


func _input(event):
	#Checks if player input event is the mouse moving
	#Set camera_change to value of mouse position relative to the previous position
	if event is InputEventMouseMotion:
		camera_change = event.relative


func cast_projectile():
	#Sets current projectile
	var projectile_current = MAGIC_ORB
	#Gets target node from root node, sets as projectile's target node
	var target = get_parent().get_node("Target/target_pos")
	
	if Input.is_action_just_pressed("cast"):
		var projectile = projectile_current.instance()
		
		var position_init = $Rig/cast_position.global_transform
		var direction_init = Vector3(sin(facing_angle), 0, cos(facing_angle))
		#Set projectile starting position, direction, and target. Add to scene tree
		projectile.start(position_init, direction_init, target)
		get_parent().add_child(projectile)


func look():
	###Camera Collision Correction
	if $Head/Pivot/camera_raycast.is_colliding():
		var move = Vector3()
		var move_direction = Vector3()
		var move_point = Vector3()
		var camera_location = $Head/Pivot/Camera.get_global_transform().origin
		var camera_location_default = $Head/Pivot/Camera_default_loc.get_global_transform().origin
		var head_location = $Head.get_global_transform().origin
		var camera_collision = $Head/Pivot/camera_raycast.get_collision_point()
		move_direction = camera_location_default.direction_to(head_location) * -0.8
		move_point = camera_collision - move_direction
		move = (move_point - camera_location)
		$Head/Pivot/Camera.global_translate(move)
	else:
		var move = Vector3()
		var camera_location_default = $Head/Pivot/Camera_default_loc.get_global_transform().origin
		var camera_location = $Head/Pivot/Camera.get_global_transform().origin
		move = camera_location_default - camera_location
		$Head/Pivot/Camera.global_translate(move)
	
	###Camera Rotating
	if camera_change.length() > 0:
			$Head.rotate_y(deg2rad(-camera_change.x * mouse_sensitivity))

			var change = camera_change.y * mouse_sensitivity
			if change + camera_angle < 88 and change + camera_angle > -88:
				$Head/Pivot.rotate_x(deg2rad(change))
				camera_angle += change
			camera_change = Vector2()


func walk(delta):
	floor_contact = $CollisionShape/raycast_floor.is_colliding()
	
	if is_on_floor():
		direction = Vector3() #Resets direction of player to default
		snap_to_ground(true)
	else:
		snap_to_ground(false)
#		velocity.x = velocity.x * cos(deg2rad (10))  #player loses some forward velocity when jumping
#		velocity.z = velocity.z * cos(deg2rad (10))

	###Camera Direction
	var aim = camera.get_global_transform().basis
	facing_angle = $Rig.get_global_transform().basis.get_euler().y
	###Directional Input
	if Input.is_action_pressed("move_forward") and is_on_floor():
		#Camera is facing along negative z, takes negative value of that and adds to z value of Vector3
		direction -= aim.z
	if Input.is_action_pressed("move_back") and is_on_floor():
		direction += aim.z
	if Input.is_action_pressed("move_left") and is_on_floor():
		direction -= aim.x
	if Input.is_action_pressed("move_right") and is_on_floor():
		direction += aim.x

	direction.y = 0
	direction = direction.normalized()
	direction_angle = atan2(direction.x, direction.z) #angle between current direction and input direction
	var turn_angle = direction_angle - facing_angle
	
	###Turn radius limiting
	if is_walking == true:
		#Turning left at degrees > 180
		if (turn_angle > deg2rad(180)):
			turn_angle = turn_angle - deg2rad(360)
		#Turning right at degrees < -180
		if (turn_angle < deg2rad(-180)):
			turn_angle = turn_angle + deg2rad(360)
		#Turn radius control left
		if (turn_angle < (-deg2rad(turn_radius)) and turn_angle > deg2rad(-180 + uturn_radius)):
			turn_angle = (-deg2rad(turn_radius))
		elif turn_angle < deg2rad(-180 + uturn_radius): #for near 180 turn
			turn_angle = -deg2rad(quick_turn_radius)
		#Turn radius control right
		if (turn_angle > (deg2rad(turn_radius)) and turn_angle < deg2rad(180 - uturn_radius)):
			turn_angle = (deg2rad(turn_radius))
		elif turn_angle > deg2rad(180 - uturn_radius): #for near 180 turn
			turn_angle = deg2rad(quick_turn_radius)
		if (direction.x != 0 or direction.z != 0):
			direction_angle = facing_angle + turn_angle
			direction.z = cos(direction_angle)
			direction.x = sin(direction_angle)

	###Velocity Calculation
	var temp_velocity = velocity
	temp_velocity.y = 0

	###Acceleration Calculation
	var target = direction * speed

	var acceleration
	if direction.dot(temp_velocity) > 0:
		acceleration = ACCEL
	else:
		acceleration = DEACCEL

	#Calculate a portion of the distance to go
	temp_velocity = temp_velocity.linear_interpolate(target, acceleration * delta)

	###Final Velocity
	if (abs(temp_velocity.x) > 0.1):
		velocity.x = temp_velocity.x
	else:
		velocity.x = 0
	if (abs(temp_velocity.z) > 0.1):
		velocity.z = temp_velocity.z
	else:
		velocity.z = 0
	
	###Player Rotation
	if (direction.x != 0 or direction.z != 0):
		$Rig.rotate_y(direction_angle - facing_angle)
		is_walking = true #is_walking set true after first pass to allow instant turn from stop
	else:
		is_walking = false
	
	###Slope Slide Prevention
	if (floor_contact and !is_walking and is_on_floor()):
		velocity.y = 0
	else:
		velocity.y += weight * gravity * delta
	
	
	###Jump
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = jump_strength
		snap_to_ground(false)
		
	###Player Movement Process	
	if (abs(velocity.x) > 0 or abs(velocity.y) > 0 or abs(velocity.z) > 0):
		velocity = move_and_slide_with_snap(velocity, snap_vector, Vector3(0,1,0), true, 1, deg2rad(65), false) #Come back/check vars 3,4,5


func snap_to_ground(is_on_floor):
	if is_on_floor:
		snap_vector = Vector3(0, -1, 0)
	else:
		snap_vector = Vector3(0, 0, 0)

###Handles passing camera values to WorldEnvironment
func skybox_rotation():
	if is_sky:
		camera_rotation.x = rad2deg(-$Head.get_rotation().y)
		if camera_rotation.x < 0:
			camera_rotation.x += 360
		camera_rotation.y = rad2deg($Head/Pivot.get_rotation().x)
		get_parent().get_node("World Environment/CanvasLayer/ColorRect/Sky").material.set_shader_param("cam_rotation", camera_rotation)
		#For Sky2:
#		get_parent().get_node("WorldEnvironment/CanvasLayer/ColorRect/Sky2").material.set_shader_param("cam_rotation", camera_rotation)


func _on_World_Environment_ready():
	is_sky = true

