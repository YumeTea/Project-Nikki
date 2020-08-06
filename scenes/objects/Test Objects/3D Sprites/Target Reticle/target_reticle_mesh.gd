extends MeshInstance


var target_location


func draw(target):
	target_location = target.get_global_transform().origin
	var local_rescale = Vector3((1.0/target.scale.x), (1.0/target.scale.y), (1.0/target.scale.z))
	self.scale = local_rescale


