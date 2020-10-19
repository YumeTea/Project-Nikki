extends Container


var max_threat_level = 100
var previous_threat_level = 0


func _on_Awareness_Meter_threat_level_changed(current_threat_level):
	$Bar.value = current_threat_level
#	animate_value(previous_threat_level, current_threat_level)
	previous_threat_level = current_threat_level


func animate_value(start_value, end_value):
	$Tween.interpolate_property($Bar, "value", start_value, end_value, 0.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
	$Tween.start()

