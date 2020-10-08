extends KinematicBody

var velocity : Vector3 = Vector3(0,-0.1,0)

func _process(delta):
	move_and_collide(velocity, true)

