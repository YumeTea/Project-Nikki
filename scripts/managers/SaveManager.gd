extends Node

"Check savegame name"

const SaveState = preload("res://scripts/custom_resources/savefile_resource.gd")

#Main Save Variables
var SAVE_FOLDER : String = "res://data/saves"
var SAVE_NAME_TEMPLATE : String = "save_file%03d.tres" # %03d means replace this with 3 digits

#Game Data Variables
const TEMP_DATA_FOLDER = "res://data/temp"
const TEMP_DATA_PATH = "res://data/temp/temp.tres"

var PLAYER_DATA_PATH = "res://data/player/player_data.tres"
onready var PLAYER_DATA_KEY = ""


#Goes through all nodes that save and has them save a pair of data and the intended path for the data
func save_main(id : int):
	var save_file := SaveState.new() # := assignment infers the type of the variant assigned to
	save_file.game_version = ProjectSettings.get_setting("application/config/version")
	
	#Find each saveable objects data if it has been saved, store it in the main save
	for object in get_tree().get_nodes_in_group("save"):
		var file : File = File.new()
		if file.file_exists(object.DATA_PATH):
			save_file.data[object.DATA_PATH] = load(object.DATA_PATH)
	
	#Make a directory object, check if save directory exists. If not, make the directory using make_dir_recursive
	var directory : Directory = Directory.new()
	if not directory.dir_exists(SAVE_FOLDER):
		directory.make_dir_recursive(SAVE_FOLDER)
	
	#Use plus_file() to assemble save path from SAVE_FOLDER, SAVE_NAME_TEMPLATE, and id
	var save_path = SAVE_FOLDER.plus_file(SAVE_NAME_TEMPLATE % id)
	var error : int = ResourceSaver.save(save_path, save_file)
	if error != OK:
		print("error saving save_main in SaveManager")


#Returns false if save file doesn't exist
func load_main(id : int):
	var save_file_path : String = SAVE_FOLDER.plus_file(SAVE_NAME_TEMPLATE % id)
	
	#Create a file object to check if the savegame exists at the save path
	var file : File = File.new()
	if not file.file_exists(save_file_path):
		print("Save file %s does not exist" % save_file_path)
		return false
	
	#Put data in the correct directories
	var save_file : Resource = load(save_file_path)
	for path in save_file.data:
		var error : int = ResourceSaver.save(path, save_file.data[path])
		if error != OK:
			print("error saving to " + str(path))
	
	return true


#Returns true if object exists and its data was saved
func save_object_data(object):
	var object_data := SaveState.new()
	object_data.game_version = ProjectSettings.get_setting("application/config/version")
	
	if object:
		object.save_data(object_data)
		
		#Make the data directory if it does not exist
		var directory : Directory = Directory.new()
		if not directory.dir_exists(TEMP_DATA_FOLDER):
			directory.make_dir_recursive(TEMP_DATA_FOLDER)
		
		var error : int = ResourceSaver.save(object.DATA_PATH, object_data)
		if error != OK:
			print("error saving to " + str(object.DATA_PATH))
			
			return true
	
	return false


#Returns true if object_data exists and object exists
func load_object_data(object):
	var object_data = load(object.DATA_PATH)

	if object_data and object:
		object.load_data(object_data)
		return true
	
	return false


func clear_temp_data():
	var directory : Directory = Directory.new()
	
	if directory.open(TEMP_DATA_FOLDER) == OK:
		directory.list_dir_begin()
		var file_name = directory.get_next()
		while file_name != "":
			directory.remove(file_name)
			file_name = directory.get_next()
	else:
		print("An error occurred when trying to access the path.")


