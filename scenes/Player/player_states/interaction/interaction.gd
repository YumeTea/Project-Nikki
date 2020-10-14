extends "res://scripts/State Machine/states/state.gd"

"""
-Find a better method to connect to signals from current level
"""

#Interaction Signals
signal input_move_direction_changed(input_direction)
signal lock_target

###Node Storage
var focus_object = null

#Initialized Values Storage
var view_mode

#Player State Storage
var state_move
var state_action
var ground_states = [
	"Walk",
]
var air_states = [
	"Jump",
	"Fall"
]
var swim_states = [
	"Swim"
]
var strafe_locked_states = [
	"Dive",
	"Bow",
	"Throw_Item",
]
var rig_locked_states = [
	"Ledge_Hang"
]

#Tween Objects Storage
var active_tweens = []

###Player Variables
onready var player_height = owner.get_node("CollisionShape").shape.height

#Entered Areas Storage
var areas_entered : Array = []

#Equipment Storage
var equipped_items = null
var equipped_weapon = null
var equipped_bow = null
var equipped_magic = null
var equipped_item = null

#View Variables
var facing_direction = Vector3()
var facing_angle = Vector2() #Goes from -pi > 0 > pi
var focus_direction = Vector3()
var focus_angle_global = Vector2()
var camera_direction = Vector3()
var camera_angle_global = Vector2()

##Move Constants
const speed_default = 18
const speed_bow_walk = 7
const speed_aerial = 3
const speed_swim = 8
const speed_ledge_move = 2.0

const surface_speed = 4
const surface_accel = 48

const ACCEL = 4
const DEACCEL = 16

const turn_radius = deg2rad(5)
const quick_turn_radius = deg2rad(12)
const uturn_radius = deg2rad(2)

#Move variables
var speed = speed_default

#Player Flags
var targetting = false


#Initializes state, changes animation, etc
func enter():
	return


#Cleans up state, reinitializes values like timers
func exit():
	return


#Creates output based on the input event passed in
"Targetting is called in both state_machine_move and state_machine_action, possible issues"
func handle_input(event):
	if event.is_action_pressed("lock_target") and event.get_device() == 0:
		if !targetting:
			targetting = true
		else:
			targetting = false


#Acts as the _process method would
func update(_delta):
	return


func on_animation_finished(_anim_name):
	return


func bound_angle(angle):
	#Angle > 180
	if (angle > deg2rad(180)):
		angle = angle - deg2rad(360)
	#Angle < -180
	if (angle < deg2rad(-180)):
		angle = angle + deg2rad(360)
	
	return angle


func get_node_direction(node):
	var direction = Vector3(0,0,1)
	var rotate_by = node.get_global_transform().basis.get_euler()
	direction = direction.rotated(Vector3(1,0,0), rotate_by.x)
	direction = direction.rotated(Vector3(0,1,0), rotate_by.y)
	direction = direction.rotated(Vector3(0,0,1), rotate_by.z)
	
	return direction


func get_transform_direction(transform):
	var direction = Vector3(0,0,1)
	var rotate_by = transform.basis.get_euler()
	direction = direction.rotated(Vector3(1,0,0), rotate_by.x)
	direction = direction.rotated(Vector3(0,1,0), rotate_by.y)
	direction = direction.rotated(Vector3(0,0,1), rotate_by.z)
	
	return direction


func calculate_local_x_rotation(direction):
	var test_direction = Vector3(direction.x, 0, direction.z)
	var x_rotation
	
	if direction.y < 0:
		x_rotation = test_direction.angle_to(direction)
	else:
		x_rotation = -test_direction.angle_to(direction)
	
	return x_rotation


func calculate_global_y_rotation(direction):
	var test_direction = Vector2(0,1)
	var direction_to = Vector2(direction.x, direction.z)
	var y_rotation = -test_direction.angle_to(direction_to)
	return y_rotation #Output is PI > y > -PI


func align_up(node_basis, normal):
	var result = Basis()
	
	result.x = normal.cross(node_basis.z)
	result.y = normal
	result.z = node_basis.x.cross(normal)
	
	result = result.orthonormalized()
	
	return result


#Returns collision data if raycast touches something
func raycast_query(from, to, exclude):
	var space_state = owner.get_world().direct_space_state
	var result = space_state.intersect_ray(from, to, [self, exclude])
	return result


func add_active_tween(property_string):
	if !active_tweens.has(property_string):
		active_tweens.append(property_string)


func remove_active_tween(property_string):
	if active_tweens.has(property_string):
		active_tweens.remove(active_tweens.find(property_string))






