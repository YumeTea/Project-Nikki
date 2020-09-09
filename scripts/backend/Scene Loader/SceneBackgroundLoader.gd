extends Control

"""
no show_error() function for load errors atm
"""

var loading_screen_scene_path = "res://scenes/UI/transition_scenes/Loading_Screen.tscn"

var loader
var wait_frames
var time_max = 100 #milliseconds
var current_scene
var loading = false
var fading = false


# Called when the node enters the scene tree for the first time.
func _ready():
	set_process(false)
	var root = get_tree().get_root()
	current_scene = root.get_child(root.get_child_count() -1)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_time):
	#Checks if loading needs to be done
	if loader == null and loading == false and fading == false: #loading is done if null is returned
		set_process(false)
		return
	
	#Waits for loading screen to fade in/transition before loading
	if get_tree().get_root().get_node("Loading_Screen/Fade_Layer/AnimationPlayer") != null:
		if get_tree().get_root().get_node("Loading_Screen/Fade_Layer/AnimationPlayer").is_playing():
			return
	
	#Clears loading screen from SceneTree
	if loading == true:
		var root = get_tree().get_root()
		current_scene = root.get_child(root.get_child_count() -2)
		current_scene.queue_free()
		loading = false
		return
	
	#Waits for loading screen to fade out/transition before loading in new scene
	if fading == true:
		if get_tree().get_root().get_node("Loading_Screen/Fade_Layer/AnimationPlayer").is_playing():
			return
		else:
			var resource = loader.get_resource()
			loader = null
			set_new_scene(resource)
			loading = true
			fading = false
			return
	
	var t = OS.get_ticks_msec()
	while OS.get_ticks_msec() < t + time_max: #use "time_max" to control for how long we block this thread
		if wait_frames > 0: #wait for frames to let the "loading..." animation show up
			wait_frames -= 1
			return
		
		#poll(advance) your loader
		var err = loader.poll()
		
		#Checks if loading is complete/updates loading progress
		if err == ERR_FILE_EOF: #finished loading on return of ERR_FILE_EOF
			get_tree().get_root().get_node("Loading_Screen/Fade_Layer/AnimationPlayer").play("Fade Out")
			fading = true
			break
		elif err == OK: #polling completed without errors on return of OK
			update_progress()
		else: #error during loading case
#			show_error()
			loader = null
			break
			
		wait_frames = 1


func goto_scene(path): #game requests to switch to scene defined by path
	var root = get_tree().get_root() #Assign root viewport to root variable 
	current_scene = root.get_child(root.get_child_count() -1) #Set node below root as current scene
	
	loader = ResourceLoader.load_interactive(path)
#	if loader == null: #checks if errors have occurred
#		show_error()
#		return
	set_process(true)

	current_scene.queue_free() #free current scene space
	
	get_tree().change_scene(loading_screen_scene_path) #Loading screen set to main scene

	wait_frames = 1 #skip 1 frame to allow the loading screen to show up


#Updates a progress bar or a paused animation
func update_progress():
	var progress = (float(loader.get_stage()) / loader.get_stage_count()) * 100
	#Update progress bar?
	get_node("/root/Loading_Screen/Fade_Layer/ColorRect/CenterContainer/VBoxContainer/TextureProgress").set_value(progress)
	
	#... or update a progress animation?
	#var length = get_node("LoadingAnimation").get_animation_length()
	
	#Call this on a paused animation. Use "true" as the second argument to force the animation to update
	#get_node("LoadingAnimation").seek(progress * length, true)


#Puts the newly loaded scene on the scene tree
func set_new_scene(scene_resource):
	#Assign loaded scene to put it in place
	current_scene = scene_resource.instance()
	#Sets loaded scene as current scene
	current_scene.connect("tree_entered", get_tree(), "set_current_scene", [current_scene], CONNECT_ONESHOT)
	#Puts loaded scene on scene tree
	get_node("/root").add_child(current_scene)

