extends KinematicBody

###Physics Variables
var direction = Vector3(0,0,0)
var velocity = Vector3(0,0,0)
const gravity = -9.8
const weight = 3

###Camera Variables
var camera_angle = 0 #stores camera angle, initial assignment is starting camera angle
var mouse_sensitivity = 0.3
var camera_change = Vector2()

###Player Movement Variables

##Walk variables
const speed = 8
#const MAX_RUNNING_SPEED = 9
const ACCEL = 6
const DEACCEL = 5

##Jump Variables
var jump_strength = 10

#func _ready():
#	pass

func _physics_process(delta):
	look()
	walk(delta)

func _input(event):
	#Checks if player input event is the mouse moving
	#Set camera_change to value of mouse position relative to the previous position
	if event is InputEventMouseMotion:
		camera_change = event.relative

func look():
	if camera_change.length() > 0:
			$Head.rotate_y(deg2rad(-camera_change.x * mouse_sensitivity))

			var change = camera_change.y * mouse_sensitivity
			if change + camera_angle < 88 and change + camera_angle > -88:
				$Head/Camera.rotate_x(deg2rad(change))
				camera_angle += change
			camera_change = Vector2()

func walk(delta):

	if is_on_floor():
		direction = Vector3() #Resets direction of player to default
	else:
		direction.x = direction.x * cos(50)  #Player loses some forward velocity when jumping
		direction.z = direction.z * cos(50) 

	###Camera Direction
	var aim = $Head/Camera.get_global_transform().basis
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
	velocity.y += weight * gravity * delta
	velocity.x = temp_velocity.x
	velocity.z = temp_velocity.z

	###Jump
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = jump_strength

	###Player Movement Process
	velocity = move_and_slide(velocity, Vector3(0,1,0), true, 3, deg2rad(60)) #Come back/check vars 3,4,5


#func _process(delta):
#	pass
