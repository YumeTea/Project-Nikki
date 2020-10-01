extends Area


func _ready():
	$AnimationPlayer.play("Flash")


func start(collision_point):
	transform.origin = collision_point

