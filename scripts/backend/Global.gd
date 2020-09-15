extends Node


signal current_scene_changed(current_scene)


#Node Storage
var Player = null
var Free_Cam = null

#Scene Variable Storage
var current_scene = null


func _ready():
	#Sets mouse to be captured by the game instead of the desktop
#	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	#Maximizes window on game start
	OS.set_window_fullscreen(true)
	
	connect_signals()


func _process(_delta):
	#Pausing
	if (Input.is_action_just_pressed("ui_cancel") and !get_tree().paused):
		get_tree().paused = true
		#$"Pause Menu".show()
		#Sets mouse cursor back to desktop mode
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		#Closes the game
		get_tree().quit()
		if (Input.is_action_just_pressed("ui_cancel") and get_tree().paused):
			get_tree().paused = false
			#$"Pause Screen".hide()
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if (Input.is_action_just_pressed("restart")):
		#Reloads current scene
		get_tree().reload_current_scene()
	
	#Set player and free cam if not set
	if not Player:
		for node in get_tree().get_nodes_in_group("actor"):
			if node.name == "Player":
				Player = node
	
	if not Free_Cam:
		for node in get_tree().get_nodes_in_group("actor"):
			if node.name == "Free_Cam":
				Free_Cam = node


func connect_signals():
		SceneManager.connect("scene_entered", self, "_on_SceneManager_scene_entered")
		SceneManager.connect("scene_exited", self, "_on_SceneManager_scene_exited")


func _on_SceneManager_scene_entered():
	#Set current scene
	current_scene = SceneManager.current_scene
	
	#Look for Player and Free Cam
	for node in get_tree().get_nodes_in_group("actor"):
		if node.name == "Player":
			Player = node
		if node.name == "Free_Cam":
			Free_Cam = node


func _on_SceneManager_scene_exited():
	#Clear player and free cam until spawning is implemented
	Player = null
	Free_Cam = null

