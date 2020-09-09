extends AnimatedSprite3D


var target_location
var reticle_scale = Vector3(0.5,0.5,0.5)


func draw(target):
	target_location = target.get_global_transform().origin
	set_global_transform(Transform(Vector3(0,0,reticle_scale.x), Vector3(0,0,reticle_scale.y), Vector3(0,0,reticle_scale.z), target_location))

















