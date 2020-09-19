extends Area


signal body_entered_trigger(body, trigger_type)


export var level_to : String = "Test Grounds"
export var gate_to : int = 1


func _on_Loading_Zone_body_entered(body):
	if body == Global.get_Player():
		SceneManager.change_scene(level_to, gate_to)
		emit_signal("body_entered_trigger", body, "Loading Zone")

