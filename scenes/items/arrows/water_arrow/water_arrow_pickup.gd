extends Area


func _process(_delta):
	rotation.y += deg2rad(1)


func _on_Water_Arrow_Pickup_body_entered(body):
	if body == Global.get_Player():
		Global.get_Player().inventory.add_item("Water Arrow", 1)
		queue_free()

