extends Label


var current_state


func update_display():
	self.text = "%s" % current_state


func _on_Debug_Value_Display_state_changed(state):
	current_state = state
	update_display()

