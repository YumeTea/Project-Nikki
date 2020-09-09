extends Node

signal current_level_changed(current_level)

var current_level
var fade_layer

var scene_reloaded = true #starts true to connect signals on scene starting
var player_voided = false
var transiting = false

func _ready():
	#Sets mouse to be captured by the game instead of the desktop
#	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	#Maximizes window on game start
	OS.set_window_fullscreen(true)


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
	
	if scene_reloaded:
		connect_signals()
	
	if player_voided:
		void_player()


func _on_scene_reloaded(is_reloaded):
	scene_reloaded = is_reloaded


func connect_signals():
		for node in get_tree().get_nodes_in_group("world"):
			current_level = node
		for node in get_tree().get_nodes_in_group("layer1"):
			if node.get_name() in ["FadeTransition"]:
				fade_layer = node
		
		if current_level:
			current_level.connect("scene_reloaded", self, "_on_scene_reloaded")
			current_level.connect("player_voided", self, "_on_player_voided")
			for node in get_tree().get_nodes_in_group("actor"):
				if node.name == "Player":
					node.get_node("Attributes").get_node("Health").connect("health_depleted", self, "_on_player_death")
			emit_signal("current_level_changed", current_level)
			scene_reloaded = false


func void_player():
		if transiting == false:
			fade_layer.get_node("AnimationPlayer").play("Fade Out")
			transiting = true
		if fade_layer.get_node("AnimationPlayer").is_playing():
			return
		else:
			transiting = false
			player_voided = false
			get_tree().reload_current_scene()
			scene_reloaded = true


func _on_player_voided(is_voided):
	if is_voided:
		player_voided = is_voided


func _on_player_death(is_death):
	if is_death:
		player_voided = true

