extends Container


var max_health
var previous_health = 0
var exaggerate_multiplier = 10


func _on_UI_In_Game_health_changed(current_health):
	animate_value(previous_health, current_health)
	previous_health = current_health


func _on_UI_In_Game_max_health_changed(new_max_health):
	max_health = new_max_health
	$Bar.max_value = new_max_health * exaggerate_multiplier


func set_count_text(value):
	$Health_Count/Amount.text = str(round(value)) + "/" + str(max_health)


func animate_value(start_value, end_value):
	$Tween.interpolate_property($Bar, "value", (start_value * exaggerate_multiplier), (end_value * exaggerate_multiplier), 2.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
	$Tween.interpolate_method(self, "set_count_text", start_value, end_value, 2.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
	$Tween.start()







