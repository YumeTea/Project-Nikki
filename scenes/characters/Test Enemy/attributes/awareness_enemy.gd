extends Node


signal spotted_target(target)
###DEBUG SIGNALS###
signal threat_level_changed(threat_level)


var threat_level : float = 0.0


func _process(delta):
	pass


func threat_increase(target, delta):
	threat_level += target.get_node("Attributes/Illumination").light_level * (delta * 2.0)
	threat_level = clamp(threat_level, 0.0, 100.0)
	emit_signal("threat_level_changed", threat_level)


func threat_decrease(delta):
	threat_level -= 5.0 * (delta * 2.0)
	threat_level = clamp(threat_level, 0.0, 100.0)

