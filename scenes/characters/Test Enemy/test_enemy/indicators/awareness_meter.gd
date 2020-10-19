extends Sprite3D


signal threat_level_changed(threat_level)


func _ready():
	texture = $Viewport.get_texture()


func _on_Awareness_threat_level_changed(threat_level):
	emit_signal("threat_level_changed", threat_level)
