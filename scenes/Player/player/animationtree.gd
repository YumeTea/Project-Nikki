extends AnimationTree


signal animation_started(anim_name)
signal animation_finished(anim_name)

var Animation_Move_State_Machine = get("parameters/StateMachineMove/playback")
var Animation_Action_State_Machine = get("parameters/StateMachineAction/playback")


func move_animation_started():
	var anim_name = Animation_Move_State_Machine.get_current_node()
	emit_signal("animation_started", anim_name)


func move_animation_finished():
	var anim_name = Animation_Move_State_Machine.get_current_node()
	emit_signal("animation_finished", anim_name)


func action_animation_started():
	var anim_name = Animation_Action_State_Machine.get_current_node()
	emit_signal("animation_started", anim_name)


func action_animation_finished():
	var anim_name = Animation_Action_State_Machine.get_current_node()
	emit_signal("animation_finished", anim_name)


func anim_print(string):
	print(string)

