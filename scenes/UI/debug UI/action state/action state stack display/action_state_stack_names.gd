extends Label


var action_state_stack = []


func _on_Debug_Value_Display_action_state_stack_changed(state_stack):
	action_state_stack = state_stack
	update_display()


func update_display():
	self.text = ""
	for state in action_state_stack.size():
		self.text += "%s" % action_state_stack[state].get_name() + "\n"


