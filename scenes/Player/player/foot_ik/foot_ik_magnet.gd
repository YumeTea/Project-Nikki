tool
extends Position3D


func _ready():
	if get_parent().name == "Foot_L_Cont":
		if owner.get_node("Rig/Skeleton/SkeletonIK_Foot_L"):
			owner.get_node("Rig/Skeleton/SkeletonIK_Foot_L").set_magnet_position(self.transform.origin)
	
	if get_parent().name == "Foot_R_Cont":
		if owner.get_node("Rig/Skeleton/SkeletonIK_Foot_R"):
			owner.get_node("Rig/Skeleton/SkeletonIK_Foot_R").set_magnet_position(self.transform.origin)

func _process(delta):
	if get_parent().name == "Foot_L_Cont":
		if owner.get_node("Rig/Skeleton/SkeletonIK_Foot_L"):
			owner.get_node("Rig/Skeleton/SkeletonIK_Foot_L").set_magnet_position(self.transform.origin)
	
	if get_parent().name == "Foot_R_Cont":
		if owner.get_node("Rig/Skeleton/SkeletonIK_Foot_R"):
			owner.get_node("Rig/Skeleton/SkeletonIK_Foot_R").set_magnet_position(self.transform.origin)
















