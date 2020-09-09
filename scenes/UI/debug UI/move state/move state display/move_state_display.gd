extends Label


var move_state


func update_display():
	self.text = "%s" % move_state


func _on_Debug_Value_Display_move_state_changed(current_move_state):
	move_state = current_move_state
	update_display()

