extends KinematicBody


onready var timer = get_node("Timer")
onready var rand_num = rand()

#Projectile Variables
var damage_dealt = 64
var speed = 60
var turn_radius = deg2rad(3)
var bob_speed = 6
var uturn
var location
var direction = Vector3()
var velocity = Vector3()
var collision

#Target Variables
var target
var target_loc
var target_dir #Direction to target

#Glow Variables
onready var light = get_node("CollisionShape/glow")
onready var mesh = get_node("CollisionShape/MeshInstance")
var glow_oscillation
var time
var time_init
var time_offset = 0.0006599
var range_default = 5.5


func _ready():
	#Set Despawn Timer
	timer.set_wait_time(15)
	timer.start()


func _process(delta):
	time = (OS.get_ticks_msec() * time_offset) + rand_num
	projectile_path(delta, time)
	glow(delta, time)
	bob(delta, time)
	pulse(time)


func start(start_loc_init, direction_init, target_node):
	transform = start_loc_init #Start transform is caster transform
	direction = direction_init #Start direction is caster direction normalized
	target = target_node


func projectile_path(delta, _time):
	location = transform.origin
	
	#Only set target location if target, else target_loc is direction player was facing
	if target != null:
		target_loc = target.get_global_transform().origin
	else:
		target_loc = self.transform.origin + direction
	
	###Projectile Direction
	var turn_dir = direction
	
	target_dir = location.direction_to(target_loc).normalized()
	
	var turn_angle_zx
	var turn_angle_zy
	var turn_angle_xy
	
	##Left/Right rotation calculations
	#Measure angle between z axis and x axis
	turn_angle_zx = (atan2(target_dir.x, target_dir.z) - atan2(turn_dir.x, turn_dir.z))
	
	#Check if target is behind so no floor/ceiling collisions
	#Can change turn radius to speed up target intersection
	if (turn_angle_zx > deg2rad(45) or turn_angle_zx < deg2rad(-45)):
		uturn = true
		turn_radius = deg2rad(5)
	else:
		uturn = false
		turn_radius = deg2rad(3)
	
	#Left/Right Turn Angle Correction for angles past 180 degrees
	if (turn_angle_zx > deg2rad(180)):
		turn_angle_zx = turn_angle_zx - deg2rad(360)
	if (turn_angle_zx < deg2rad(-180)):
		turn_angle_zx = turn_angle_zx + deg2rad(360)
	#Left/Right Turn Radius Limiting
	if turn_angle_zx > turn_radius: #Left
		turn_angle_zx = turn_radius
	if turn_angle_zx < -turn_radius: #Right
		turn_angle_zx = -turn_radius
		
	turn_dir = turn_dir.rotated(Vector3(0, 1, 0), turn_angle_zx)
	
	##Up/Down rotation calculations
	#Measure angle between z axis and y axis
	turn_angle_zy = -(atan2(target_dir.y, target_dir.z) - atan2(turn_dir.y, turn_dir.z))
	
	if uturn:
		turn_angle_zy = 0
	
	#Up/Down Turn Angle Correction for angles past 180 degrees
	if (turn_angle_zy > deg2rad(180)):
		turn_angle_zy = turn_angle_zy - deg2rad(360)
	if (turn_angle_zy < deg2rad(-180)):
		turn_angle_zy = turn_angle_zy + deg2rad(360)
	#Up/Down Turn Radius Limiting
	if turn_angle_zy > turn_radius:
		turn_angle_zy = turn_radius
	if turn_angle_zy < -turn_radius:
		turn_angle_zy = -turn_radius
		
	turn_dir = turn_dir.rotated(Vector3(1, 0, 0), turn_angle_zy)
	
	#Measure angle between x axis and y axis
	turn_angle_xy = (atan2(target_dir.y, target_dir.x) - atan2(turn_dir.y, turn_dir.x))
	
	if uturn:
		turn_angle_xy = 0
	
	#Up/Down Turn Angle Correction for angles past 180 degrees
	if (turn_angle_xy > deg2rad(180)):
		turn_angle_xy = turn_angle_xy - deg2rad(360)
	if (turn_angle_xy < deg2rad(-180)):
		turn_angle_xy = turn_angle_xy + deg2rad(360)
	#Up/Down Turn Radius Limiting
	if turn_angle_xy > turn_radius:
		turn_angle_xy = turn_radius
	if turn_angle_xy < -turn_radius:
		turn_angle_xy = -turn_radius
		
	turn_dir = turn_dir.rotated(Vector3(0, 0, 1), turn_angle_xy)
	
	direction += (turn_dir - direction)
	
	###Projectile Velocity
	velocity = direction * speed * delta
	
	###Projectile Movement
	
	###Projectile Movement and Collision
	collision = move_and_collide(velocity, false, false, true)
	
	if collision:
		impact(collision)
	else:
		velocity = move_and_collide(velocity, false, false)


func impact(collision_object):
	var collider = collision_object.collider
	for actor in get_tree().get_nodes_in_group("vulnerable"):
		if actor == collider:
			collider.take_damage(damage_dealt)
	queue_free()


# warning-ignore:shadowed_variable
func glow(_delta, time):
	glow_oscillation = ((abs(cos(time)) + 1.5) / 3.0) * range_default
	$CollisionShape/glow.set_param(3, glow_oscillation)
	
# warning-ignore:shadowed_variable
func bob(_delta, time):
	$CollisionShape.transform.origin.y = (sin(time * bob_speed)) * 0.5
	$CollisionShape.transform.origin.x = cos(time * bob_speed * 0.5)
	$CollisionShape.transform.origin.z = sin(time * bob_speed * 0.8)
	
# warning-ignore:shadowed_variable
func pulse(time):
	mesh.get_surface_material(0).set_shader_param("time", time)
	mesh.get_surface_material(0).set_shader_param("time2", time)
	
func rand():
	var nums = [30,61,57,6,34,32,51,49,22,52,60,47,12,43,1,7,10,18,38,0,21,2,5,28,14,13,45,36,35,11,25,4,59,29,62,16,37,17,20,44,23,24,53,58,42,48,54,27,50,8,56,9,33,55,64,31,46,19,41,3,40,15,39,26] #list to choose from
	return nums[randi() % nums.size()]


func _on_Timer_timeout():
	queue_free()

