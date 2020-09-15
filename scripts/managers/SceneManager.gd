extends Node


signal scene_entered
signal scene_exited


export var initial_scene : String = "Test Grounds"
export var initial_gate : int = 1

#Load Storage
var player_instance
var free_cam_instance

#Scene Storage
var player_scene = "res://scenes/Player/player/Player.tscn"
var free_cam_scene = "res://scenes/camera/free cam/Free_Cam.tscn"

#Scene Variable Storage
var current_scene = null

#Scene Change Flags
var next_scene = null
var next_gate = null
var changing_scene = false
var transiting = false
var load_new_scene = false
var new_scene_loaded = false


func _ready():
	player_instance = load(player_scene)
	free_cam_instance = load(free_cam_scene)
	next_scene = initial_scene
	next_gate = initial_gate
	transiting = true
	SceneBackgroundLoader.connect("scene_loaded", self, "_on_SceneBackgroundLoader_scene_loaded")


func _process(delta):
	if transiting:
		change_scene(next_scene, next_gate)


#Use gate value once entry points are implemented
func change_scene(scene_name, gate_idx):
	transiting = true
	
	next_scene = scene_name
	next_gate = gate_idx
	
	#Code for exiting scene
	if current_scene != scene_name and load_new_scene == false:
		load_new_scene = transit_player_out()
		
		if load_new_scene:
			var scene_path = SceneDatabase.get_scene(scene_name).scene_path
			
			#Start loading sequence and clear current scene
			SceneBackgroundLoader.goto_scene(scene_path)
			current_scene = null
			
			#Clear player and free cam until spawning is implemented
			Global.Player = null
			Global.Free_Cam = null
			
			emit_signal("scene_exited")
	
	#Code to run once scene is in scene tree from SceneBackgroundLoader
	elif new_scene_loaded:
		#Assign current scene variable and emit it
		current_scene = scene_name
		load_new_scene = false
		new_scene_loaded = false
		
		emit_signal("scene_entered")
	
	#Code for entering scene
	if current_scene == scene_name:
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
						Global.Player = player_node
						Global.Free_Cam = free_cam_node
						player_node.global_transform = gate.global_transform
						print(Global.Player.owner.name)
		
		transiting = !transit_player_in()


#Returns true if transit out complete, else returns false
func transit_player_out():
	if Global.Player and Global.Free_Cam:
		if !transiting:
			Global.Free_Cam.get_node("Overlay/AnimationPlayer").play("Fade_Out")
		
		if Global.Free_Cam.faded_out:
			return true
		
		return false
	
	else:
		return true


#Returns true if transit in complete, else returns false
func transit_player_in():
	if Global.Player and Global.Free_Cam:
		if !Global.Free_Cam.get_node("Overlay/AnimationPlayer").is_playing():
			Global.Free_Cam.get_node("Overlay/AnimationPlayer").play("Fade_In")
		
		if !Global.Free_Cam.faded_out:
			return true
			
		return false
	
	return false


func _on_SceneBackgroundLoader_scene_loaded():
	new_scene_loaded = true









