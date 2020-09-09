extends Node

"""
Check if level path is correct through loading sequence
"""

signal player_initialized(player)

var level
var scene_reloaded
var player

func _ready():
	Global.connect("current_level_changed", self, "_on_current_level_changed")


func _process(_delta):
	if not player:
		initialize_player()
		return


func initialize_player():
	for node in get_tree().get_nodes_in_group("actor"):
		if node.name == "Player":
			player = node
	if not player:
		return
	
	emit_signal("player_initialized", player)
	
	player.inventory.connect("inventory_changed", self, "_on_Player_inventory_changed")
	
	var existing_inventory = load("user://inventory.tres")
	if existing_inventory:
		#Get items of saved inventory and set them in current loaded inventory
		player.inventory.set_items(existing_inventory.get_items())
	else:
		#set default inventory values here
		initialize_equipment()
		player.inventory.add_item("Water_Arrow", 12)
		player.inventory.add_item("Fire_Arrow", 5)


func initialize_equipment():
	player.inventory.add_item("Weapon_None", 1)
	player.inventory.add_item("Bow_None", 1)
	player.inventory.add_item("Keeper_Bow", 1)
	player.inventory.add_item("Magic_None", 1)
	player.inventory.add_item("Arrow_None", 1)
	player.inventory.add_item("Item_None", 1)
	
	player.inventory.equip_item("Weapon_None")
	player.inventory.equip_item("Bow_None")
	player.inventory.equip_item("Magic_None")
	player.inventory.equip_item("Arrow_None")
	player.inventory.equip_item("Item_None")
	


func _on_Player_inventory_changed(_inventory):
	#Save inventory everytime it changes
#	ResourceSaver.save("user://inventory.tres", inventory)
	return


func _on_current_level_changed(current_level):
	level = current_level.get_path()


















