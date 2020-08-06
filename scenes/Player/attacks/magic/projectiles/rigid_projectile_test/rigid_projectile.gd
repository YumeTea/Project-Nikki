extends RigidBody


var speed = 30


func _ready():
	contact_monitor = true
	contacts_reported = 100


func start(start_loc_init, direction_init, target_node):
	transform = start_loc_init
	set_linear_velocity(direction_init * speed)
	set_gravity_scale(3)


func _process(delta):
	print()


func _on_Projectile_body_entered(body):
	queue_free()
