extends "res://scenes/Player/player_states/action/action.gd"

"""
Focus_angle.x is a frame behind when centering
Check if previous arrow is freed on equipping different arrow
Arrow child during firing is not removed from parent before adding to world?
"""

onready var Bow_IK = owner.get_node("Rig/Skeleton/Bow_IK")
onready var Arrow_Position = owner.get_node("Rig/Skeleton/Hand_R/Arrow_Position")
onready var skeleton = owner.get_node("Rig/Skeleton")

const bow_blend_pos = 0.99
const xfade_in_time = 0.25
const xfade_out_time = 0.5

var equipped_arrow
var arrow
var drawing_arrow
var arrow_ready
var arrow_drawn
var cancel_draw

var bow_angle = Vector2()
const bow_up_travel_lim = 0.76
const bow_down_travel_lim = 0.3


func initialize(init_values_dic):
	for value in init_values_dic:
		self[value] = init_values_dic[value]


#Initializes state, changes animation, etc
func enter():
	#Start drawing_arrow at true
	drawing_arrow = true
	arrow_ready = false
	arrow_drawn = false
	cancel_draw = false
	
	#Reset bow angle value on entering
	bow_angle = Vector2(0,0)
	
	#Load the arrow model
	if equipped_items["Arrow"] != null:
		equipped_arrow = equipped_items["Arrow"]
		arrow = load(equipped_arrow.item_reference.item_scene)
	else:
		arrow = preload("res://scenes/Player/attacks/arrows/blank_arrow/blank_arrow.tscn")
	
	#Add arrow projectile to player rig
	projectile = arrow.instance()
	Arrow_Position.add_child(projectile)
	set_arrow_visible(false)
	
	#Connect to player signals
	connect_player_signals()
	
	#Start animation
	start_anim_1d_action("Draw_Arrow", bow_blend_pos, xfade_in_time)
	
	.enter()


#Cleans up state, reinitializes values like timers
func exit():
	stop_ik_bow()
	
	anim_fade_out_1d_action(xfade_out_time)
	
	#Reset bow angle of Bow_IK on exiting
	reset_bow_angle()
	
	#If arrow is still attached to player, queue free the arrow
	if projectile:
		if Arrow_Position.has_node(projectile.name):
			projectile.queue_free()
	
	disconnect_player_signals()
	.exit()


func handle_input(event):
	#Pressing draw bow again after cancelling restarts draw
	if event.is_action_pressed("draw_bow"):
		if cancel_draw:
			cancel_draw = false
	
	#When player lets go of bow button
	if !Input.is_action_pressed("draw_bow"):
		if arrow_drawn:
			fire_arrow()
		else:
			if arrow_ready:
				owner.get_node("AnimationTree").set("parameters/TimeScaleAction/scale", -2.0)
	elif !cancel_draw:
		owner.get_node("AnimationTree").set("parameters/TimeScaleAction/scale", 1.0)
	
	if event.is_action_pressed("cancel") and event.get_device() == 0:
		if arrow_ready:
				cancel_draw = true
				arrow_drawn = false
				drawing_arrow = true
				owner.get_node("AnimationTree").set("parameters/TimeScaleAction/scale", -2.0)
	
	.handle_input(event)


func update(delta):
	if !drawing_arrow and !arrow_drawn:
		emit_signal("finished", "none")
	
	#Make bow follow focus angle
	pivot_bow()
	
	.update(delta)


func on_animation_started(anim_name):
	if anim_name == "Draw_Arrow":
		if !Input.is_action_pressed("draw_bow"):
			drawing_arrow = false


func on_animation_finished(anim_name):
	if anim_name == "Draw_Arrow" and !cancel_draw:
		drawing_arrow = false
		arrow_drawn = true


func fire_arrow():
	Arrow_Position.remove_child(projectile)
	
	#Initialize and spawn projectile
	var position_init = Bow_IK.get_node("Projectile_Position").global_transform
	var direction_init = get_node_direction(Bow_IK.get_node("Projectile_Position"))
	#Set projectile starting position, direction, and target. Add to scene tree
	projectile.start(position_init, direction_init)
	world.add_child(projectile) #Set projectile's parent as current level's node
	projectile.set_owner(world)
	
	#Set flags to false to end state
	arrow_drawn = false
	drawing_arrow = false
	
	owner.inventory.remove_item(equipped_arrow.item_reference.name, 1)
	emit_signal("finished", "none")


#Pivots bow and arrow to focus angle, and moves arm in or out based on focus angle
func pivot_bow():
	focus_angle.x = calculate_local_x_rotation(focus_direction)
	
	Bow_IK.rotate_x(focus_angle.x - bow_angle.x)
	
	bow_angle.x += focus_angle.x - bow_angle.x
	
	
	#Bow hold distance offsetting
	var bow_offset
	#Looking up
	if focus_angle.x <= 0:
		bow_offset = (((focus_angle.x / deg2rad(57.5)) * bow_up_travel_lim))
		Bow_IK.get_node("Hand_L_Controller").transform.origin.z = bow_offset
		Bow_IK.get_node("Hand_R_Controller").transform.origin.z = bow_offset
	#Looking down
	if focus_angle.x > 0:
		bow_offset = (((focus_angle.x / deg2rad(57.5)) * bow_down_travel_lim))
		Bow_IK.get_node("Hand_L_Controller").transform.origin.z = bow_offset
		Bow_IK.get_node("Hand_R_Controller").transform.origin.z = bow_offset


func reset_bow_angle():
	Bow_IK.rotate_x(-bow_angle.x)


func set_arrow_visible(visible_bool):
	if projectile:
		if Arrow_Position.has_node(projectile.name):
			if visible_bool == true:
				print("setting_arrow_visible")
				Arrow_Position.get_node(projectile.name).visible = true
			elif visible_bool == false:
				print("setting_arrow_invisible")
				Arrow_Position.get_node(projectile.name).visible = false
	
	return


func set_arrow_ready(ready_bool):
	arrow_ready = ready_bool


func stop_ik_bow():
	if skeleton.get_node("SkeletonIK_Bow").is_running() or skeleton.get_node("SkeletonIK_Arrow").is_running():
		skeleton.get_node("SkeletonIK_Bow").stop()
		skeleton.get_node("SkeletonIK_Arrow").stop()
		skeleton.clear_bones_global_pose_override()





