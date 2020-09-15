extends Node

var scenes_folder = "res://resources/main_scenes/"
var scenes = Array()

func _ready():
	#Populate the items array with all scenes
	var directory = Directory.new()
	directory.open(scenes_folder)
	directory.list_dir_begin()
	
	var file = directory.get_next()
	while(file):
		if not directory.current_is_dir():
			scenes.append(load(scenes_folder + "/%s" % file))
	
		file = directory.get_next()


func get_scene(scene_name):
	for s in scenes:
		if s.name == scene_name:
			return s
			
	return null
