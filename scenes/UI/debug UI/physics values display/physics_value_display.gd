extends Label

var current_height = 0
var current_velocity = Vector3()
var current_horizontal_velocity = 0
var player_y_translate = 3


func update_display():
	self.text = "%s" % current_height + "\n"
	self.text += "%s" % current_velocity.y + "\n"
	self.text += "%s" % current_horizontal_velocity + "\n"


func _on_Debug_Value_Display_position_changed(position):
	current_height = stepify(position.y, 0.001) - 3
	update_display()


func _on_Debug_Value_Display_velocity_changed(velocity):
	current_velocity = velocity
	current_velocity.y = stepify(current_velocity.y, 0.001)
	current_horizontal_velocity = stepify(calculate_horizontal_velocity(velocity), 0.001)
	update_display()


func calculate_horizontal_velocity(current_velocity):
	var horizontal_velocity = Vector2(current_velocity.x, current_velocity.z).length()
	return horizontal_velocity

