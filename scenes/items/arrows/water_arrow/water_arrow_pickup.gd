extends Area


func _process(_delta):
	rotation.y += deg2rad(1)


func _on_Water_Arrow_Pickup_body_entered(body):
	if body == GameManager.player:
		GameManager.player.inventory.add_item("Water_Arrow", 1)
		queue_free()

