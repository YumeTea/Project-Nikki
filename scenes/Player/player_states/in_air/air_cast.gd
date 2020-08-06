extends "res://scenes/Player/player_states/action/action.gd"

#Initialization storage
var enter_velocity = Vector3()
var is_cast_jump


func initialize(init_values_dic):
	for value in init_values_dic:
		self[value] = init_values_dic[value]

#Initializes state, changes animation, etc
func enter():
	.enter()
	cast_jump = false #cast jump should be complete on entering air_cast state
	finished_casting = false
	connect_player_signals()
	if !owner.get_node("AnimationPlayer").is_playing() and finished_casting == false:
		owner.get_node("AnimationPlayer").play("Casting")


#Cleans up state, reinitializes values like timers
func exit():
	.exit()
	is_falling = false
	disconnect_player_signals()


#Creates output based on the input event passed in
func handle_input(event):
	.handle_input(event)


#Acts as the _process method would
func update(delta):
	.update(delta)
	cast_projectile()
	if is_casting == false:
		emit_signal("finished", "previous")
		return
	if owner.is_on_floor():
		is_falling = false
		emit_signal("landed", height)
		emit_signal("finished", "ground_cast")
	if velocity.y < 0 and is_falling == false:
		emit_signal("started_falling", position.y)
		is_falling = true


func _on_AnimationPlayer_animation_finished(anim_name):
	return

