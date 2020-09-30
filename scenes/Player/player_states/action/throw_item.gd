extends "res://scenes/Player/player_states/action/action.gd"


onready var Bow_IK = owner.get_node("Rig/Skeleton/Bow_IK")
onready var Item_Position = owner.get_node("Rig/Skeleton/Hand_R/Item_Position")

#Animation Variables
const throw_blend_pos = 1.0
const xfade_in_time = 0.1
const xfade_out_time = 0.25

#Item Storage
var item

var throw_angle

const projectile_pos_transform = Vector3(0,0,5)


func initialize(init_values_dic):
	for value in init_values_dic:
		self[value] = init_values_dic[value]


#Initializes state, changes animation, etc
func enter():
	#Reset bow angle value on entering
	throw_angle = Vector2(0,0)
	
	#Load the item model
	equipped_item = equipped_items["Item"]
	item = load(equipped_item.item_reference.item_scene)
	
	#Add itemprojectile to player rig
	projectile = item.instance()
	Item_Position.add_child(projectile)
	set_item_visible(false)
	
	#Connect to player signals
	connect_player_signals()
	
	#Start animation
	start_anim_1d_right_arm("Throw_Item", throw_blend_pos, xfade_in_time)
	
	#Allow left arm anim to continue blending in if something is equipped
	if equipped_items["Bow"]:
		owner.get_node("AnimationTree").set("parameters/MovexLeftArm/blend_amount", 1.0)
	
	.enter()


#Cleans up state, reinitializes values like timers
func exit():
	anim_fade_out_1d_right_arm(xfade_out_time)
	
	#Reset bow angle of Bow_IK on exiting
	reset_throw_angle()
	
	#If arrow is still attached to player, queue free the arrow
	if projectile:
		if Item_Position.has_node(projectile.name):
			projectile.queue_free()
	
	disconnect_player_signals()
	.exit()


func handle_input(event):
	if event.is_action_pressed("debug_input") and event.get_device() == 0:
		print(owner.get_node("AnimationTree").get("parameters/MovexAction/blend_amount"))
	.handle_input(event)


func update(delta):
	#Make throw follow focus angle
	pivot_throw()
	
	.update(delta)


func on_animation_started(_anim_name):
	return


func on_animation_finished(anim_name):
	if anim_name == "Throw_Item":
		emit_signal("finished", "none")


func throw_item():
	Item_Position.remove_child(projectile)
	
	#Initialize and spawn projectile
	var position_init = Bow_IK.get_node("Projectile_Position").global_transform
	var direction_init = get_node_direction(Bow_IK.get_node("Projectile_Position"))
	#Set projectile starting position, direction, and target. Add to scene tree
	projectile.start(position_init, direction_init)
	world.add_child(projectile) #Set projectile's parent as current level's node
	projectile.set_owner(world)
	
#	owner.inventory.remove_item(equipped_item.item_reference.name, 1)


#Pivots throw angle to focus angle
func pivot_throw():
	focus_angle.x = calculate_local_x_rotation(focus_direction)
	
	Bow_IK.rotate_x(focus_angle.x - throw_angle.x)
	
	throw_angle.x += focus_angle.x - throw_angle.x


func reset_throw_angle():
	Bow_IK.rotate_x(-throw_angle.x)


func set_item_visible(visible_bool):
	if projectile:
		if Item_Position.has_node(projectile.name):
			if visible_bool == true:
				Item_Position.get_node(projectile.name).visible = true
			elif visible_bool == false:
				Item_Position.get_node(projectile.name).visible = false
	
	return





