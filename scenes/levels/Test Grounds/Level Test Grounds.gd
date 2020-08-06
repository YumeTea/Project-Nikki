extends Spatial


signal player_voided(is_voided)
signal scene_reloaded(is_reloaded)


onready var load_area = false
onready var blackout = false


func _ready():
	emit_signal("scene_reloaded", true)


func _process(_delta):
	if load_area == true:
		if $Layer1/FadeTransition/AnimationPlayer.is_playing():
			return
		else:
			SceneBackgroundLoader.goto_scene("res://scenes/levels/Level Black Expanse.tscn")


func _on_Loading_Zone_body_entered(body):
	if (body.get_name() == "Player") and load_area == false:
		$Layer1/FadeTransition/AnimationPlayer.play("Fade Out")
		load_area = true


func _on_Void_Plane_body_entered(body):
	if (body.get_name() == "Player"):
		var voided = true
		emit_signal("player_voided", voided)


func _on_Void_Plane2_body_entered(body):
	if (body.get_name() == "Player"):
		var voided = true
		emit_signal("player_voided", voided)

