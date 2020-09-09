tool
extends Position3D


func _ready():
	if Engine.editor_hint:
		if get_parent() is SkeletonIK:
			get_parent().set_magnet_position(self.transform.origin)


func _process(delta):
	if Engine.editor_hint and visible:
		if get_parent() is SkeletonIK:
			get_parent().set_magnet_position(self.transform.origin)
















