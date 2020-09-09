extends Node

signal health_changed(health_change)
signal health_depleted(health_depleted)
signal max_health_changed(new_max_health)

var health = 0
export(int) var max_health = 64


func _ready():
	health = max_health
	emit_signal("health_changed", health)
	emit_signal("max_health_changed", max_health)


func take_damage(value):
	health -= value
	health = max(0, health) #keeps health from being negative
	emit_signal("health_changed", health)
	if health == 0:
		health_depleted()


func heal(amount):
	health += amount
	health = min(health, max_health)
	emit_signal("health_changed", health)


func health_depleted():
	var death = true
	emit_signal("health_depleted", death)












