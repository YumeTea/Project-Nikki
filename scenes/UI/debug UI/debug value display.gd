extends Control


signal state_changed(current_state)
signal position_changed(current_position)
signal velocity_changed(current_velocity)
signal is_falling(is_falling)
signal targets_changed(targettable_objects)
signal focus_target(target_pos_node)
signal state_stack_changed(state_stack)


func _on_State_Machine_state_changed(current_state):
	emit_signal("state_changed", current_state)


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


func _on_State_Machine_state_stack_changed(state_stack):
	emit_signal("state_stack_changed", state_stack)

