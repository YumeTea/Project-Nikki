extends "res://scenes/characters/Test Enemy/enemy_states/action/action.gd"


func initialize(init_values_dic):
	for value in init_values_dic:
		self[value] = init_values_dic[value]


#Initializes state, changes animation, etc
func enter():
	.enter()
	is_falling = false
	cast_jump = false
	finished_casting = false
	connect_enemy_signals()
	if !owner.get_node("AnimationPlayer").is_playing() and finished_casting == false:
		owner.get_node("AnimationPlayer").play("Casting")


#Cleans up state, reinitializes values like timers
func exit():
	.exit()
	disconnect_enemy_signals()


#Creates output based on the input event passed in
func handle_input(event):
#	if event.is_action_pressed("jump") and event.get_device() == 0:
#		cast_jump = true
#		emit_signal("finished", "jump")
	.handle_input(event)


func handle_ai_input(input):
	.handle_ai_input(input)


#Acts as the _process method would
func update(delta):
	if !movement_locked:
		walk_free(delta)
	else:
		walk_locked(delta)
	cast_projectile()
	if is_casting == false:
		emit_signal("finished", "previous")
	if !owner.is_on_floor():
		cast_jump = true
		emit_signal("finished", "fall")
	.update(delta)


func _on_AnimationPlayer_animation_finished(_anim_name):
	return

