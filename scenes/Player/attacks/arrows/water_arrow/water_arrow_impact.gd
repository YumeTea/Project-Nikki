extends Spatial

func _ready():
	$AnimationPlayer.play("Water_Arrow_Impact")

func start(collision_point):
	transform.origin = collision_point

