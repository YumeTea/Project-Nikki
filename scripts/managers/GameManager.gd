extends Node

"""
Check if scene path is correct through loading sequence
"""

signal player_initialized(player)
signal player_exited_scene(level_to, gate_to)
signal player_respawned
signal player_voided


#Node Storage
var Player = null
var Free_Cam = null

#Load Storage
var player_instance = load("res://scenes/Player/player/Player.tscn")
var free_cam_instance = load("res://scenes/camera/free cam/Free_Cam.tscn")

#Scene Variable Storage
var current_scene = null
var next_scene = null
var next_gate = null
var load_next_scene = false

#Level Flags
var spawn_player = false
var void_player = false

#Player Flags
var player_voided = false


func _ready():
	SceneManager.connect("scene_entered", self, "_on_SceneManager_scene_entered")
	SceneManager.connect("scene_exited", self, "_on_SceneManager_scene_exited")


func _process(_delta):
	if spawn_player:
		spawn_player(1)
	
	if player_voided:
		void_player()

"When player is found, make SaveManager set inventory, health, and view mode"
func initialize_player():
	#Checks to make sure Global.get_Player() is a node
	if not Global.get_Player():
		print("Global.get_Player() is null")
		return
	
	#Load player values when initializing
	var loaded_save = SaveManager.load_data(001)
	
	if !loaded_save:
		initialize_equipment()
	
	emit_signal("player_initialized", Global.get_Player())


func initialize_equipment():
	Global.get_Player().inventory.add_item("Keeper Bow", 1)
	Global.get_Player().inventory.add_item("Water Arrow", 12)
	Global.get_Player().inventory.add_item("Fire Arrow", 5)


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
					var player_node = player_instance.instance()
					var free_cam_node = free_cam_instance.instance()
					node.add_child(player_node)
					node.add_child(free_cam_node)
					player_node.set_owner(get_tree().current_scene)
					free_cam_node.set_owner(get_tree().current_scene)
					Global.set_Player(player_node)
					Global.set_Free_Cam(free_cam_node)
					player_node.global_transform = gate.global_transform
					break
	
	#Fade in on free cam and set spawn player to false
	if Global.get_Free_Cam():
		Global.get_Free_Cam().get_node("Overlay/AnimationPlayer").play("Fade_In")
		spawn_player = false
		
		SaveManager.load_data(001)
		emit_signal("player_respawned")


func void_player():
		if void_player == false:
			#Save player values on voiding
			SaveManager.save_data(001)
			
			Global.get_Free_Cam().get_node("Overlay/AnimationPlayer").play("Fade_Out")
			void_player = true
			emit_signal("player_voided")
		if Global.get_Free_Cam().get_node("Overlay/AnimationPlayer").is_playing():
			return
		else:
			#Free player on voiding
			Global.get_Player().queue_free()
			Global.set_Player(null)
			Global.get_Free_Cam().queue_free()
			Global.set_Free_Cam(null)
			void_player = false
			player_voided = false
			spawn_player = true


#Returns true if transit in complete or there is no player (main menu)
#Player needs to be in scene before calling this if player is intended to be in scene
func transit_to_scene(scene_type, gate_idx):
	if scene_type == "Level":
		#Add player and camera to scene
		if !Global.get_Player() and !Global.get_Free_Cam():
			add_player_to_scene(gate_idx)
	
	if Global.get_Player():
		if Global.get_Free_Cam():
			if !Global.get_Free_Cam().get_node("Overlay/AnimationPlayer").is_playing():
				Global.get_Free_Cam().get_node("Overlay/AnimationPlayer").play("Fade_In")
			
			if !Global.get_Free_Cam().faded_out:
				return true
			
		return false
	
	else:
		return true


#Returns true if transit out complete or there is no player (main menu)
func transit_from_scene():
	if Global.get_Player():
		if Global.get_Free_Cam():
			if !SceneManager.transiting:
				#Save player values on leaving scene
				SaveManager.save_data(001)
				
				Global.get_Free_Cam().get_node("Overlay/AnimationPlayer").play("Fade_Out")
				SceneManager.transiting = true
			
			if Global.get_Free_Cam().faded_out:
				return true
		
		return false
	
	else:
		return true


func add_player_to_scene(gate_idx):
	#Find gate and add player and camera to scenetree at that point, then initialize player
	for gate in get_tree().get_nodes_in_group("gate"):
		if gate.gate_idx == gate_idx:
			for node in get_tree().get_nodes_in_group("group_node"):
				if node.name == "Actors":
					var player_node = player_instance.instance()
					var free_cam_node = free_cam_instance.instance()
					node.add_child(player_node)
					node.add_child(free_cam_node)
					player_node.set_owner(get_tree().current_scene)
					free_cam_node.set_owner(get_tree().current_scene)
					Global.set_Player(player_node)
					Global.set_Free_Cam(free_cam_node)
					player_node.global_transform = gate.global_transform
					
					initialize_player()


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
		if body == Global.get_Player():
			player_voided = true
		else:
			for node in get_tree().get_nodes_in_group("actor"):
				if node == body:
					node.queue_free()











