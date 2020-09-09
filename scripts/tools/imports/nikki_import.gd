tool
extends EditorScenePostImport

var scene_name = "NikkiCharacterModel"
var head_mesh_name = "Head"
var body_mesh_name = "Body Simplified"
var skeleton
var rig_path = "Rig/"
var head_materials = [
	preload("res://models/characters/Nikki/materials/Hair.material"),
	preload("res://models/characters/Nikki/materials/Eyes.material"),
	preload("res://models/characters/Nikki/materials/Skin.material"),
]
var body_materials = [
	preload("res://models/characters/Nikki/materials/Shirt.material"),
	preload("res://models/characters/Nikki/materials/Skin.material"),
	preload("res://models/characters/Nikki/materials/Eyes.material"),
	preload("res://models/characters/Nikki/materials/Striped_Socks.material"),
	preload("res://models/characters/Nikki/materials/Shorts.material"),
]

func post_import(scene):
	scene.set_name(scene_name)
	
	#Moves Skeleton to be child of root node and deletes previous parent
	for child in scene.get_children():
		if child.name == "Rig":
			for object in child.get_children():
				if object.name == "Skeleton":
					skeleton = object
					child.remove_child(skeleton)
					scene.add_child(skeleton)
					skeleton.set_owner(scene)
					for item in skeleton.get_children():
						item.set_owner(scene)
			child.queue_free()

	#Applies materials to character mesh
	for child in scene.get_children():
		if child.name == "Skeleton":
			for mesh in child.get_children():
				if mesh.name == head_mesh_name:
					for material in range (0, mesh.get_surface_material_count()):
						mesh.set_surface_material(material, head_materials[material])
				if mesh.name == body_mesh_name:
					for material in range (0, mesh.get_surface_material_count()):
						mesh.set_surface_material(material, body_materials[material])

	#Renames animation track names to paths expected by player animationplayer
#		if child.name == "AnimationPlayer":
#			for animation in child.get_animation_list():
#				for track in range (0, child.get_animation(animation).get_track_count()):
#					var track_path = child.get_animation(animation).track_get_path(track)
#					track_path = str(rig_path) + str(track_path)
#					child.get_animation(animation).track_set_path(track, track_path)
					
	
	return scene

