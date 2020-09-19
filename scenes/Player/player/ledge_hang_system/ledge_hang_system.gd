extends Spatial


func _on_Area_body_entered(body):
	if body.name == Global.current_scene:
		print(body.name)
