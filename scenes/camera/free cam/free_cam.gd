extends Spatial


signal free_cam_position_changed(free_cam_position)


var player
var view_obscured
var free_camera_transform


func _ready():
	for node in get_tree().get_nodes_in_group("actors"):
		if node.get_name() in ["Player"]:
			player = node
			player.get_node("Camera_Rig").connect("camera_moved", self, "_on_camera_moved")
			player.get_node("Camera_Rig").connect("view_blocked", self, "_on_view_blocked")


func _on_view_blocked(is_obscured):
	view_obscured = is_obscured


func _on_camera_moved(player_camera_transform):
	self.transform = player_camera_transform
	emit_signal("free_cam_position_changed", self.get_global_transform().origin)


func animate_movement(start_value, end_value):
	$Tween.interpolate_property(self, "free_camera_transform", start_value, end_value, 2.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
	$Tween.start()












