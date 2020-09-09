extends Label


var move_state_stack = []


func _on_Debug_Value_Display_move_state_stack_changed(state_stack):
	move_state_stack = state_stack
	update_display()


func update_display():
	self.text = ""
	for state in move_state_stack.size():
		self.text += "%s" % move_state_stack[state].get_name() + "\n"

