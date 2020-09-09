extends Node

var items_folder = "res://resources/items"
var items = Array() #will be an array of dictionaries



func _ready():
	#Populate the items array with all possible items
	var directory = Directory.new()
	directory.open(items_folder)
	directory.list_dir_begin()
	
	var file = directory.get_next()
	while(file):
		if not directory.current_is_dir():
			items.append(load(items_folder + "/%s" % file))
	
		file = directory.get_next()


func get_item(item_name):
	for i in items:
		if i.name == item_name:
			return i
			
	return null




















