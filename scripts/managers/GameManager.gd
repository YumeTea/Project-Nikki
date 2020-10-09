extends Node

"""
Check if scene path is correct through loading sequence
"""

signal player_initialized(player)
signal player_exited_scene(level_to, gate_to)
signal player_respawned
signal player_voided


#DEBUG VALUES
export var initial_scene : String = "Test Grounds"
export var initial_gate : int = 1


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

###DEBUG###
var initialize_player


func _ready():
	#Connect to SceneManager signals
	SceneManager.connect("scene_entered", self, "_on_SceneManager_scene_entered")
	SceneManager.connect("scene_exited", self, "_on_SceneManager_scene_exited")
	
	#Clear temp data files if they exist before initializing world or loading saved temp files
	SaveManager.clear_temp_data()
	
	###DEBUG LINES###
	#Set values to initialize player due to loading level scene directly
	initialize_player = true
	spawn_player = true
	SceneManager.current_scene = initial_scene
	#Change to starting scene
#	SceneManager.change_scene(initial_scene, initial_gate)


func _process(_delta):
	if spawn_player:
		spawn_player(1)
	
	if player_voided:
		void_player()
	
	###DEBUG###
	if initialize_player:
		initialize_player()
		initialize_player = false


func initialize_player():
	#Checks to make sure Global.get_Player() is a node
	if not Global.get_Player():
		print("Global.get_Player() is null")
		return
	
	#Load player values when initializing
	var existing_player = SaveManager.load_object_data(Global.get_Player())
	
	if !existing_player or initialize_player:
		initialize_equipment()
	
	emit_signal("player_initialized", Global.get_Player())


func initialize_equipment():
	Global.get_Player().inventory.add_item("Keeper Bow", 1)
	Global.get_Player().inventory.add_item("Water Arrow", 12)
	Global.get_Player().inventory.add_item("Ice Arrow", 10)
	Global.get_Player().inventory.add_item("Fire Arrow", 10)
	Global.get_Player().inventory.add_item("Icosphere", 18)


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
	
	#Fade in on free cam and set spawn player flag to false
	if Global.get_Free_Cam():
		Global.get_Free_Cam().get_node("AnimationPlayer").play("Fade_In")
		spawn_player = false
		
		SaveManager.save_object_data(Global.get_Player())
		
		emit_signal("player_respawned")


func void_player():
		#Save player temp values and initialize voiding of player
		if void_player == false:
			#Save player values on voiding
			SaveManager.save_object_data(Global.get_Player())
			
			Global.get_Free_Cam().get_node("AnimationPlayer").play("Fade_Out")
			void_player = true
			player_voided = true
			emit_signal("player_voided")
		#Wait for fade out to complete before removing player
		if Global.get_Free_Cam().get_node("AnimationPlayer").is_playing():
			return
		#Remove player relevant nodes and set flags to respawn player
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
			initialize_player()
	
	if Global.get_Player():
		if Global.get_Free_Cam():
			if !Global.get_Free_Cam().get_node("AnimationPlayer").is_playing():
				Global.get_Free_Cam().get_node("AnimationPlayer").play("Fade_In")
			
			if !Global.get_Free_Cam().faded_out:
				return true
			
		return false
	
	else:
		return true


func transit_from_scene():
	if Global.get_Player():
		if Global.get_Free_Cam():
			if !SceneManager.transiting:
				#Save player values on leaving scene
				SaveManager.save_object_data(Global.get_Player())
				
				Global.get_Free_Cam().get_node("AnimationPlayer").play("Fade_Out")
				
				SceneManager.transiting = true
			
			if Global.get_Free_Cam().faded_out:
				return true
			else:
				return false
		
		else:
			SceneManager.transiting = true
			return true
	
	else:
		SceneManager.transiting = true
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











