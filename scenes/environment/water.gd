tool
extends Area


export (String, "None", "Water") var type

var surface_height

func _ready():
	set_water_texture_scale()
	surface_height = $CollisionShape/Surface.global_transform.origin.y


func set_water_texture_scale():
	var scale_factor = Vector2(scale.x, scale.z) / 4.0
	
	#Rescale surface texture
	$CollisionShape/Surface.get_surface_material(0).set_shader_param("tile_factor", scale_factor)
	
	#Rescale time offset
	var amplitude = $CollisionShape/Surface.get_surface_material(0).get_shader_param("amplitude")
	amplitude = Vector2(1.0 / scale_factor.x, 1.0 / scale_factor.y)
	$CollisionShape/Surface.get_surface_material(0).set_shader_param("amplitude", amplitude)


func _on_Water_body_entered(body):
	for actor in get_tree().get_nodes_in_group("actor"):
		if actor == body:
			actor._entered_area(type, surface_height)


func _on_Water_body_exited(body):
	for actor in get_tree().get_nodes_in_group("actor"):
		if actor == body:
			actor._exited_area(type)



func _on_Water_area_entered(area):
	if area == Global.get_Free_Cam():
		area._entered_area(type, surface_height)


func _on_Water_area_exited(area):
		if area == Global.get_Free_Cam():
			area._exited_area(type)



