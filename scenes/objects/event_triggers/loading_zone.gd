extends Area


signal body_entered_trigger(body, trigger_type)


export var level_to : String
export var gate_to : int


func _on_Loading_Zone_body_entered(body):
	if body == Global.Player:
		SceneManager.change_level(level_to, gate_to)
		emit_signal("body_entered_trigger", body, "Void")

