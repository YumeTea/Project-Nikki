extends Label


var state_stack = []


func _on_Debug_Value_Display_state_stack_changed(state_stack_array):
	state_stack = state_stack_array
	update_display()


func update_display():
	self.text = ""
	for state in state_stack.size():
		self.text += "%s" % state_stack[state].get_name() + "\n"

