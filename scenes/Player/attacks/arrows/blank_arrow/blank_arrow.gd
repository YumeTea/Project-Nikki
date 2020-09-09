extends KinematicBody


func _ready():
	set_physics_process(false)


func start(_position_init, _direction_init):
	set_physics_process(true)


func _physics_process(_delta):
	queue_free()

