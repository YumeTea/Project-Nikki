extends HBoxContainer


func _on_UI_In_Game_light_level_changed(current_light_level):
	$MarginContainer/NinePatchRect/Light_Gem.get_material().set_shader_param("light_level", current_light_level)

