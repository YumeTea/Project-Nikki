extends Node


signal scene_entered
signal scene_exited


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
	SceneBackgroundLoader.connect("scene_loaded", self, "_on_SceneBackgroundLoader_scene_loaded")


func _process(delta):
	#Run change_scene function while transiting between scenes
	if transiting:
		change_scene(next_scene, next_gate)


#Use gate value once entry points are implemented
func change_scene(scene_name, gate_idx):
	next_scene = scene_name
	next_gate = gate_idx
	
	#Code for exiting scene
	if current_scene != scene_name and load_new_scene == false:
		load_new_scene = GameManager.transit_from_scene()
		
		if load_new_scene:
			var scene_path = SceneDatabase.get_scene(scene_name).scene_path
			
			#Start loading sequence and clear current scene
			SceneBackgroundLoader.goto_scene(scene_path)
			current_scene = null
			
			#Clear player and free cam until spawning is implemented
			Global.set_Player(null)
			Global.set_Free_Cam(null)
			
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
		transiting = !GameManager.transit_to_scene(SceneDatabase.get_scene(scene_name).type, gate_idx)


func _on_SceneBackgroundLoader_scene_loaded():
	new_scene_loaded = true









