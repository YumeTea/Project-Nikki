extends Control


signal move_state_changed(current_move_state)
signal move_state_stack_changed(move_state_stack)
signal action_state_changed(current_action_state)
signal action_state_stack_changed(action_state_stack)
signal position_changed(current_position)
signal velocity_changed(current_velocity)
signal is_falling(is_falling)
signal targets_changed(targettable_objects)
signal focus_target(target_pos_node)


func _on_State_Machine_Move_move_state_changed(move_state):
	emit_signal("move_state_changed", move_state)


func _on_State_Machine_Move_move_state_stack_changed(move_state_stack):
	emit_signal("move_state_stack_changed", move_state_stack)


func _on_State_Machine_Action_action_state_changed(action_state):
	emit_signal("action_state_changed", action_state)


func _on_State_Machine_Action_action_state_stack_changed(action_state_stack):
	emit_signal("action_state_stack_changed", action_state_stack)


func _on_Nikkiv2_position_changed(current_position):
	emit_signal("position_changed", current_position)


func _on_Nikkiv2_velocity_changed(current_velocity):
	emit_signal("velocity_changed", current_velocity)


func _on_Nikkiv2_is_falling(is_falling):
	emit_signal("is_falling", is_falling)


func _on_Nikkiv2_targets_changed(targettable_objects):
	emit_signal("targets_changed", targettable_objects)


func _on_Nikkiv2_focus_target(target_pos_node):
	emit_signal("focus_target", target_pos_node)












