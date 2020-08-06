extends Spatial


onready var load_area = false


func _ready():
	pass


func _process(delta):
	if load_area == true:
		if $Layer1/FadeTransition/AnimationPlayer.is_playing() == true:
			return
		else:
			SceneBackgroundLoader.goto_scene("res://scenes/levels/Level Test Grounds.tscn")
	pass


func _on_Loading_Zone_body_entered(body):
	$Layer1/FadeTransition/AnimationPlayer.play("Fade Out")
	load_area = true


