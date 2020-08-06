extends "res://scenes/characters/Test Enemy/enemy_states/motion.gd"


###Projectile Variables
var MAGIC_ORB = preload("res://scenes/characters/Test Enemy/attacks/magic/magic_orb_enemy/magic_orb_enemy.tscn")
var projectile_time = 0
var projectile_count = 0
var is_casting = false
var finished_casting = false
var cast_jump

#Initializes state, changes animation, etc
func enter():
	owner.get_node("AnimationPlayer").connect("animation_finished", self, "_on_animation_finished")

#Cleans up state, reinitializes values like timers
func exit():
	owner.get_node("AnimationPlayer").disconnect("animation_finished", self, "_on_animation_finished")


#Creates output based on the input event passed in
func handle_input(event):
	.handle_input(event)


func handle_ai_input(input):
	.handle_ai_input(input)


#Acts as the _process method would
func update(delta):
	.update(delta)


func _on_animation_finished(anim_name):
	if anim_name == "Casting":
		finished_casting = true


func target():
	return


func cast_projectile():
	#Sets current projectile
	var projectile_current = MAGIC_ORB
	#Sets facing angle to character model direction
	var facing_angle = owner.get_node("Rig").get_global_transform().basis.get_euler().y
	#Gets target node from root node, sets as projectile's target node
	var target_pos = focus_target_pos
	
	owner.get_node("Rig").get_node("cast_position").get_node("cast_glow").visible = true
	
	if is_casting == false:
		is_casting = true
		finished_casting = false
	
	elif is_casting == true:
		if finished_casting:
			var projectile = projectile_current.instance()
	
			#Initialize and spawn projectile
			var position_init = owner.get_node("Rig").get_node("cast_position").global_transform
			var direction_init = Vector3(sin(facing_angle), 0, cos(facing_angle))
			#Set projectile starting position, direction, and target. Add to scene tree
			projectile.start(position_init, direction_init, target_pos)
			owner.get_node("Projectile Elements").add_child(projectile) #Set projectile's parent as Projectiles node

			is_casting = false
			finished_casting = false
			owner.get_node("Rig").get_node("cast_position").get_node("cast_glow").visible = false
			owner.get_node("AnimationPlayer").stop(true)


func set_initialized_values(init_values_dic):
	for value in init_values_dic:
		init_values_dic[value] = self[value]

