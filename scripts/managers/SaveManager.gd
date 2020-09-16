extends Node

"Check savegame name"

const SaveState = preload("res://scripts/custom_resources/savegame_resource.gd")

var SAVE_FOLDER : String = "res://data/saves"
var SAVE_NAME_TEMPLATE : String = "save_%03d.tres" # %03d means replace this with 3 digits


func save_data(id : int):
	var save_game := SaveState.new() # := assignment infers the type of the variant assigned to
	save_game.game_version = ProjectSettings.get_setting("application/config/version")
	
	#Go through each node in the save group and have them save to save_game
	for node in get_tree().get_nodes_in_group("save"):
		node.save_data(save_game)
	
	#Make a directory object, check if save directory exists. If not, make the directory using make_dir_recursive
	var directory : Directory = Directory.new()
	if not directory.dir_exists(SAVE_FOLDER):
		directory.make_dir_recursive(SAVE_FOLDER)
	
	#Use plus_file() to assemble save path from SAVE_FOLDER, SAVE_NAME_TEMPLATE, and id
	var save_path = SAVE_FOLDER.plus_file(SAVE_NAME_TEMPLATE % id)
	var error : int = ResourceSaver.save(save_path, save_game)
	if error != OK:
		print("error saving state in SaveManager")


#Returns false if save file doesn't exist
func load_data(id : int):
	var save_file_path : String = SAVE_FOLDER.plus_file(SAVE_NAME_TEMPLATE % id)
	
	#Create a file object to check if the savegame exists at the save path
	var file : File = File.new()
	if not file.file_exists(save_file_path):
		print("Save file %s does not exist" % save_file_path)
		return false
	
	var save_game : Resource = load(save_file_path)
	for node in get_tree().get_nodes_in_group("save"):
		node.load_data(save_game)
	
	return true
