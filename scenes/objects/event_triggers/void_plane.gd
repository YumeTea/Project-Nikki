extends Area

signal body_entered_trigger(body, trigger_type)


func _on_Void_Plane_body_entered(body):
	emit_signal("body_entered_trigger", body, "Void")

