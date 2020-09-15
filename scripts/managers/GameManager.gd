extends Node

"""
Check if scene path is correct through loading sequence
"""

signal player_initialized(player)
signal player_respawned
signal player_voided


#Node Storage
var Player = null
var Free_Cam = null

#Scene Variable Storage
var current_scene = null

#Level Flags
var spawn_player = false
var void_player = false

#Player Flags
var player_voided = false


func _ready():
	SceneManager.connect("scene_entered", self, "_on_SceneManager_scene_entered")
	SceneManager.connect("scene_exited", self, "_on_SceneManager_scene_exited")


func _process(_delta):
	if not Player:
		if Global.Player:
			initialize_player()
#	if not Free_Cam:
#		if Global.Free_Cam:
#			Free_Cam = Global.Free_Cam
	
	if spawn_player:
		spawn_player(1)
	
	if player_voided:
		void_player()


func initialize_player():
	#Currently player is only stored here so initialize player runs once
	Player = Global.Player
	
	if not Player:
		return
	
	emit_signal("player_initialized", Global.Player)
	
	Global.Player.inventory.connect("inventory_changed", self, "_on_Player_inventory_changed")
	
	var existing_inventory = load("user://inventory.tres")
	if existing_inventory:
		#Get items of saved inventory and set them in current loaded inventory
		Global.Player.inventory.set_items(existing_inventory.get_items())
	else:
		#set default inventory values here
		initialize_equipment()


func initialize_equipment():
	Global.Player.inventory.add_item("Keeper Bow", 1)
	Global.Player.inventory.add_item("Water Arrow", 12)
	Global.Player.inventory.add_item("Fire Arrow", 5)


func _on_Player_inventory_changed(_inventory):
	#Save inventory everytime it changes
#	ResourceSaver.save("user://inventory.tres", inventory)
	return


func spawn_player(gate_idx):
	#Find gate and add player and camera to scenetree at that point
	for gate in get_tree().get_nodes_in_group("gate"):
		if gate.gate_idx == gate_idx:
			for node in get_tree().get_nodes_in_group("group_node"):
				if node.name == "Actors":
					var player_node = SceneManager.player_instance.instance()
					var free_cam_node = SceneManager.free_cam_instance.instance()
					node.add_child(player_node)
					node.add_child(free_cam_node)
					player_node.set_owner(get_tree().current_scene)
					free_cam_node.set_owner(get_tree().current_scene)
					Global.Player = player_node
					Global.Free_Cam = free_cam_node
					player_node.global_transform = gate.global_transform
					break
	
	#Fade in on free cam and set spawn player to false
	if Global.Free_Cam:
		Global.Free_Cam.get_node("Overlay/AnimationPlayer").play("Fade_In")
		spawn_player = false
		
		emit_signal("player_respawned")


func void_player():
		if void_player == false:
			Global.Free_Cam.get_node("Overlay/AnimationPlayer").play("Fade_Out")
			void_player = true
			emit_signal("player_voided")
		if Global.Free_Cam.get_node("Overlay/AnimationPlayer").is_playing():
			return
		else:
			#Free player on voiding
			Global.Player.queue_free()
			Global.Player = null
			Global.Free_Cam.queue_free()
			Global.Free_Cam = null
			void_player = false
			player_voided = false
			spawn_player = true


func connect_signals():
	for node in get_tree().get_nodes_in_group("trigger"):
		node.connect("body_entered_trigger", self, "_on_body_entered_trigger")


func _on_SceneManager_scene_entered():
	if SceneManager.current_scene:
		current_scene = SceneManager.current_scene
		connect_signals()


func _on_SceneManager_scene_exited():
	current_scene = SceneManager.current_scene


func _on_Player_voided(is_voided):
	if is_voided:
		player_voided = is_voided


func _on_Player_death(is_death):
	if is_death:
		player_voided = true


func _on_body_entered_trigger(body, trigger_type):
	if trigger_type == "Void":
		if body == Global.Player:
			player_voided = true
		else:
			for node in get_tree().get_nodes_in_group("actor"):
				if node == body:
					node.queue_free()











