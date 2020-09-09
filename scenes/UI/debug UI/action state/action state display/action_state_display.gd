extends Label


var action_state


func update_display():
	self.text = "%s" % action_state


func _on_Debug_Value_Display_action_state_changed(current_action_state):
	action_state = current_action_state
	update_display()



