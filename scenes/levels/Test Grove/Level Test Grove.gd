extends Spatial


onready var load_area = false


#func _ready():
#	pass


func _process(delta):
	if load_area == true:
		if $FadeTransition/AnimationPlayer.is_playing() == true:
			return
		else:
			SceneBackgroundLoader.goto_scene("res://scenes/levels/Level Black Expanse.tscn")
	pass


func _on_Loading_Zone_body_entered(body):
	$FadeTransition/AnimationPlayer.play("Fade Out")
	load_area = true


func _on_Void_Plane_body_entered(body):
	$FadeTransition/AnimationPlayer.play("Fade Out")
	if body is KinematicBody:
		get_tree().reload_current_scene()
