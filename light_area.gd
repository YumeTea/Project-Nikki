extends Area


onready var light_radius = get_parent().omni_range + 5.0 #should be slightly larger than light range


func _ready():
	$CollisionShape.shape.radius = light_radius


func _on_Light_Area_body_entered(body):
	if body.is_in_group("illuminatable"):
		body.get_node("Attributes/Illumination")._enter_light(get_parent())


func _on_Light_Area_body_exited(body):
	if body.is_in_group("illuminatable"):
		body.get_node("Attributes/Illumination")._exit_light(get_parent())





