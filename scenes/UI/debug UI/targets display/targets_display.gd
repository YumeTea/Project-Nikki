extends Label


var targets_array = []


func _on_Debug_Value_Display_targets_changed(targettable_objects):
	targets_array = targettable_objects
	update_display()

func update_display():
	self.text = ""
	for target in targets_array:
		self.text += "%s" % target.get_name() + "\n"

