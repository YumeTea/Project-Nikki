extends Control

signal health_changed(health_change)
signal max_health_changed(new_max_health)
signal is_falling(is_falling)


func _on_Health_health_changed(current_health):
	emit_signal("health_changed", current_health)


func _on_Health_max_health_changed(new_max_health):
	emit_signal("max_health_changed", new_max_health)

