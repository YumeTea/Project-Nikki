extends Spatial


var target_location
var scale_factor = 1.6
var reticle_scale = Vector3(3, 3, 3)


func draw(target):
	target_location = target.get_global_transform().origin
	set_global_transform(Transform(Vector3(0,0,scale_factor), Vector3(0,0,scale_factor), Vector3(0,0,scale_factor), target_location))


func set_frame(frame_number):
	for node in get_children():
		node.visible = false
	get_child(frame_number).visible = true
















