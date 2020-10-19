extends "res://scenes/Player/player_states/move/motion.gd"

"""
Fails to climb up seemingly valid ledges after turning corners
Remember to reset camera rig transform when animating origin
How to blend animations between end of climb up and next animation?
Frame after animation finished could translate skeleton back to default
"""


#Node Storage
onready var Raycast_Wall = Ledge_Grab_System.get_node("Area/Raycast_Wall")
onready var Raycast_Ledge = Ledge_Grab_System.get_node("Area/Raycast_Ledge")
onready var Raycast_Facing_Wall = Ledge_Grab_System.get_node("Raycast_Facing_Wall")
onready var Raycast_Facing_Ledge = Ledge_Grab_System.get_node("Raycast_Facing_Ledge")
onready var Raycast_Ceiling = Ledge_Grab_System.get_node("Raycast_Ceiling")

onready var collider_shape = owner.get_node("CollisionShape").shape

onready var collisionshape_offset_default = Player_Collision.transform.origin
onready var target_pos_offset_default = owner.get_node("Target_Pos").transform.origin

#Space Query Variables
var space_rid
var space_state
var query_shape
var intersections : Array

export var translate_amount : Vector3


func initialize(init_values_dic):
	for value in init_values_dic:
		self[value] = init_values_dic[value]


#Initializes state, changes animation, etc
func enter():
	translate_amount = Vector3(0,0,-0.3)
	
	translate_up_forward(Player_Collision, collisionshape_offset_default, translate_amount)
	translate_up_forward(owner.get_node("Target_Pos"), target_pos_offset_default, translate_amount)
	
	connect_player_signals()
	
	if owner.get_node("AnimationTree").get("parameters/StateMachineMove/playback").is_playing() == false:
		owner.get_node("AnimationTree").get("parameters/StateMachineMove/playback").start("Ledge_Climb")
	else:
		owner.get_node("AnimationTree").get("parameters/StateMachineMove/playback").travel("Ledge_Climb")
	
	.enter()


#Cleans up state, reinitializes values like timers
func exit():
	###Place player object relative to collision transform and reset translated collision and target pos
	translate_player_to_collision()
	
	skeleton.set_bone_pose(skeleton.find_bone("controller"), Transform())
	skeleton.set_bone_pose(skeleton.find_bone("bone"), Transform())
	
	snap_vector = snap_vector_default
	
	disconnect_player_signals()
	
	.exit()


#Creates output based on the input event passed in
func handle_input(event):
	.handle_input(event)


#Acts as the _process method would
func update(delta):
	#Translate player collision and player's target_pos
	translate_up_forward(Player_Collision, collisionshape_offset_default, translate_amount)
	translate_up_forward(owner.get_node("Target_Pos"), target_pos_offset_default, translate_amount)
	
	if check_object_collisions() == true:
		print("intersection detected in ledge_climb")
		emit_signal("finished", "fall")


func on_animation_started(_anim_name):
	return


func on_animation_finished(anim_name):
	if anim_name == "Ledge_Climb":
		emit_signal("finished", "walk")


func check_object_collisions():
	#World Space RID
	space_rid = owner.get_world().space
	
	#Get PhysicsDirectSpaceState
	space_state = PhysicsServer.space_get_direct_state(space_rid)
	
	#Create shape to query
	query_shape = PhysicsShapeQueryParameters.new()
	query_shape.transform = Player_Collision.global_transform
	query_shape.set_shape(collider_shape)
	query_shape.collision_mask = 0x40001
	
	#Get intersection points on query shape
	intersections = space_state.collide_shape(query_shape)
	
	#Debug Visualizer
	if intersections.size() > 0:
		return true
	else:
		return false


func translate_up_forward(object, object_offset_default, translate_offset : Vector3):
	facing_direction = get_node_direction(Rig)
	var forward_translate
	
	forward_translate = facing_direction * translate_offset.z
	
	object.transform.origin.x = forward_translate.x + object_offset_default.x
	object.transform.origin.z = forward_translate.z + object_offset_default.z
	object.transform.origin.y = translate_offset.y + object_offset_default.y


func translate_player_to_collision():
	owner.global_transform.origin = Player_Collision.global_transform.origin - collisionshape_offset_default
	Player_Collision.transform.origin = collisionshape_offset_default
	owner.get_node("Target_Pos").transform.origin = target_pos_offset_default


