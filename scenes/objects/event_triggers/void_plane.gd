extends Area

signal body_entered_trigger(body, trigger_type)


func _on_Void_Plane_body_entered(body):
	if body == Global.get_Player():
		GameManager.void_player()
	else:
		for actor in get_tree().get_nodes_in_group("actor"):
			if actor == body:
				body.queue_free()

