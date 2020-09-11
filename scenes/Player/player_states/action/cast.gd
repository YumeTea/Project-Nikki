extends "res://scenes/Player/player_states/action/action.gd"


const cast_blend_pos = 0.99
const xfade_in_time = 0.25
const xfade_out_time = 0.5


func initialize(init_values_dic):
	for value in init_values_dic:
		self[value] = init_values_dic[value]


#Initializes state, changes animation, etc
func enter():
	is_casting = true
	finished_casting = false
	
	start_anim_1d_action("Casting_Magic_Orb", cast_blend_pos, xfade_in_time)
	owner.get_node("AnimationTree").set("parameters/MovexLeftHand/blend_amount", 1.0)
	
	connect_player_signals()
	.enter()


#Cleans up state, reinitializes values like timers
func exit():
	anim_fade_out_1d_action(xfade_out_time)
	owner.get_node("AnimationTree").set("parameters/MovexLeftHand/blend_amount", 0.0)
	
	disconnect_player_signals()
	.exit()


#Creates output based on the input event passed in
func handle_input(event):
	.handle_input(event)


#Acts as the _process method would
func update(delta):
	cast_projectile()
	if is_casting == false:
		emit_signal("finished", "none")
	.update(delta)


func on_animation_finished(anim_name):
	if anim_name == "Casting_Magic_Orb":
		finished_casting = true


func cast_projectile():
	#Sets current projectile
	var projectile_current = MAGIC_ORB #determined by inventory value in future
	#Sets facing angle to character model direction
	var facing_angle = owner.get_node("Rig").get_global_transform().basis.get_euler().y
	#Gets target node from root node, sets as projectile's target node
	var target_pos = focus_object
	
	
	if is_casting == false:
		is_casting = true
		finished_casting = false
	
	elif is_casting == true:
		if finished_casting:
			projectile = projectile_current.instance()
	
			#Initialize and spawn projectile
			var position_init = owner.get_node("Rig/Projectile_Position").global_transform
			var direction_init = Vector3(sin(facing_angle), 0, cos(facing_angle))
			#Set projectile starting position, direction, and target. Add to scene tree
			projectile.start(position_init, direction_init, target_pos)
			world.add_child(projectile) #Set projectile's parent as Projectiles node

			is_casting = false
			finished_casting = false

