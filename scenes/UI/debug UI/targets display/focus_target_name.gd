extends Label


var text_color
var focus_target


func _ready():
	self.set("custom_colors/font_color", text_color)

func _on_Debug_Value_Display_focus_target(target_pos_node):
	focus_target = target_pos_node
	update_display()


func update_display():
	if focus_target != null:
		self.set("custom_colors/font_color", Color(1,0,0,1))
		self.text = "%s" % focus_target.get_name()
	else:
		self.set("custom_colors/font_color", Color(1,1,1,1))
		self.text = "%s" % focus_target

