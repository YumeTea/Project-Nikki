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
var anim_folder : String = "res://models/characters/Nikki/model/temp/anim"


func post_import(scene):
	scene.set_name(scene_name)
	
	###NODE REARRANGEMENT###
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
	
	###MATERIAL APPLICATION###
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
	
	###ANIMATIONS###
	#Clear temp anim folder
	var directory : Directory = Directory.new()
	
	if directory.open(anim_folder) == OK:
		directory.list_dir_begin(true)
		var file_name = directory.get_next()
		while file_name != "":
			directory.remove(file_name)
			file_name = directory.get_next()
	else:
		print("An error occurred when trying to access %s" % anim_folder)
	
	#Save anims to temp anim folder
	for anim in scene.get_node("AnimationPlayer").get_animation_list():
		var anim_resource = scene.get_node("AnimationPlayer").get_animation(anim)
		anim_resource.step = 0.0166666 #change FPS to 60
		
		var save_path = anim_folder.plus_file("%s.anim" % anim_resource.resource_name)

		var error : int = ResourceSaver.save(save_path, anim_resource)
		if error != OK:
			print("error saving anim in nikki_import.gd")
	
	
	return scene












