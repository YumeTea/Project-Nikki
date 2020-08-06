extends Label


var is_falling


func _on_Debug_Value_Display_is_falling(falling):
	is_falling = falling
	update_display()

func update_display():
		self.text = ""
		self.text += "%s" % is_falling

