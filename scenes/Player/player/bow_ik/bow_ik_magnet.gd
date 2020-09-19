tool
extends Position3D


func _ready():
	if get_parent().name == "Hand_L_Cont":
		if owner.get_node("Rig/Skeleton/SkeletonIK_Bow"):
			owner.get_node("Rig/Skeleton/SkeletonIK_Bow").set_magnet_position(owner.get_node("Rig").to_local(self.global_transform.origin))
	
	if get_parent().name == "Hand_R_Cont":
		if owner.get_node("Rig/Skeleton/SkeletonIK_Arrow"):
			owner.get_node("Rig/Skeleton/SkeletonIK_Arrow").set_magnet_position(owner.get_node("Rig").to_local(self.global_transform.origin))


func _process(delta):
	if get_parent().name == "Hand_L_Cont":
		if owner.get_node("Rig/Skeleton/SkeletonIK_Bow"):
			owner.get_node("Rig/Skeleton/SkeletonIK_Bow").set_magnet_position(owner.get_node("Rig").to_local(self.global_transform.origin))
	
	if get_parent().name == "Hand_R_Cont":
		if owner.get_node("Rig/Skeleton/SkeletonIK_Arrow"):
			owner.get_node("Rig/Skeleton/SkeletonIK_Arrow").set_magnet_position(owner.get_node("Rig").to_local(self.global_transform.origin))

