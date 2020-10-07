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
var ANIM_FOLDER : String = "res://models/characters/Nikki/model/anims/"
var ANIM_FOLDER_TEMP : String = "res://models/characters/Nikki/model/temp/anim"
var CHARACTER_MODEL_SAVE_PATH : String = "res://models/characters/Nikki/model/Nikki Character Model.tscn"



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
	var directory_anim_temp : Directory = Directory.new()

	if directory_anim_temp.open(ANIM_FOLDER_TEMP) == OK:
		directory_anim_temp.list_dir_begin(true)
		var file_name = directory_anim_temp.get_next()
		while file_name != "":
			directory_anim_temp.remove(file_name)
			file_name = directory_anim_temp.get_next()
	else:
		print("An error occurred when trying to access %s" % ANIM_FOLDER_TEMP)
	
	#Iterate through imported anims
	for anim in scene.get_node("AnimationPlayer").get_animation_list():
		var anim_found = false
		
		var anim_resource = scene.get_node("AnimationPlayer").get_animation(anim)
		anim_resource.step = 0.0166666 #change FPS to 60
		anim_resource.loop = true
		
		var directory_anim : Directory = Directory.new()
	
		if directory_anim.open(ANIM_FOLDER) == OK:
			directory_anim.list_dir_begin(true)
			var file_name = directory_anim.get_next()
			while file_name != "":
				if file_name == "%s.anim" % anim:
					var anim_saved = load(ANIM_FOLDER.plus_file(file_name))
					
					#Copy same tracks from new anim to saved anim
					for track in anim_resource.get_track_count():
						anim_saved.remove_track(anim_saved.find_track(anim_resource.track_get_path(track)))
						anim_resource.copy_track(track, anim_saved)
					
					#Save modified anim
					var save_path = ANIM_FOLDER.plus_file("%s.anim" % anim)
					
					var error : int = ResourceSaver.save(ANIM_FOLDER.plus_file(file_name), anim_saved)
					if error != OK:
						print("error saving anim in nikki_import.gd")
					anim_found = true
					break
				
				file_name = directory_anim.get_next()
		
		#Save anim in temp anim folder if it wasn't found on player anim player
		if !anim_found:
			var save_path = ANIM_FOLDER_TEMP.plus_file("%s.anim" % anim)
			
			var error : int = ResourceSaver.save(save_path, anim_resource)
			if error != OK:
				print("error saving anim in nikki_import.gd")
	
	#Delete AnimationPlayer
	scene.get_node("AnimationPlayer").free()
	
	###SCENE SAVING###
	#Save character model scene
	var scene_resource = PackedScene.new()
	
	var result = scene_resource.pack(scene)
	if result == OK:
		var error : int = ResourceSaver.save(CHARACTER_MODEL_SAVE_PATH, scene_resource)
		if error != OK:
			print("error saving %s" % scene.name)
	
	
	return scene












