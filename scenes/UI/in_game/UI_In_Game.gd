extends Control

signal health_changed(health_change)
signal max_health_changed(new_max_health)
signal equipped_items_changed(equipped_items_dict)
signal is_falling(is_falling)

var Player = null


func _process(delta):
	if not Player:
		if Global.Player:
			Player = Global.Player
			Player.inventory.connect("equipped_items_changed", self, "_on_Player_equipped_items_changed")
			
			#Emit initial equipment if player is found
			emit_signal("equipped_items_changed", Player.inventory.equipped_items.duplicate())


func _on_Health_health_changed(current_health):
	emit_signal("health_changed", current_health)


func _on_Health_max_health_changed(new_max_health):
	emit_signal("max_health_changed", new_max_health)


func _on_Player_equipped_items_changed(equipped_items_dict):
	emit_signal("equipped_items_changed", equipped_items_dict)





