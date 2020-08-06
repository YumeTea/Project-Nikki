extends Area

var speed = 16
var direction
var velocity

func _ready():
	pass # Replace with function body.


func _process(delta):
	projectile_path(delta)


func start(location_init, direction_init, target_node):
	transform = location_init
	direction = direction_init
	velocity = direction * speed


func projectile_path(delta):
	transform.origin += velocity * delta


func _on_Area_Projectile_body_entered(body):
	queue_free()

