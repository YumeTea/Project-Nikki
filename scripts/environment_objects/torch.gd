extends StaticBody


onready var timer = get_node("Timer")
onready var rand_num = rand()


#Child Storage
onready var light = get_node("CollisionShape/Light")
onready var mesh = get_node("CollisionShape/MeshInstance")

#Glow variables
const range_default = 20
const bob_speed = 1
var light_radius
var light_radius_default = 20
var time
var time_init
var time_offset = 0.0006599

#Torch Variables
const extinguish_time = 60
var extinguish_time_left = 60
var time_on_extinguish
var relight_time = 60
var relight_time_left = 60
var time_on_relight

#Torch Flags
var lit = true
var extinguishing = false
var relighting = false


func _ready():
	#Set Despawn Timer
	timer.set_wait_time(15)
	timer.start()


func _process(_delta):
	if extinguishing:
		extinguish()
	elif relighting:
		relight()
	else:
		time = (OS.get_ticks_msec() * time_offset) + rand_num
		pulse(time)


func glow(_delta, t):
	light_radius = (abs(cos(t)) + range_default)
	$CollisionShape/Light.set_param(3, light_radius) #3 is reference for range


func bob(_delta, t):
	$CollisionShape.transform.origin.y = (sin(t * bob_speed)) * 0.1


func pulse(t):
	mesh.get_surface_material(0).set_shader_param("time", t)
	mesh.get_surface_material(0).set_shader_param("time2", t)


func rand():
	var nums = [30,61,57,6,34,32,51,49,22,52,60,47,12,43,1,7,10,18,38,0,21,2,5,28,14,13,45,36,35,11,25,4,59,29,62,16,37,17,20,44,23,24,53,58,42,48,54,27,50,8,56,9,33,55,64,31,46,19,41,3,40,15,39,26] #list to choose from
	return nums[randi() % nums.size()]


func hit_effect(effect_type):
	if effect_type == "water":
		if lit:
			light_radius = $CollisionShape/Light.get_param(3)
			time = (time / (PI))
			time -= floor(time)
			time = time * PI
			extinguish_time_left = extinguish_time
			extinguishing = true
			relighting = false
	if effect_type == "fire":
		if !lit:
			relight_time_left = relight_time
			relighting = true
			extinguishing = false


func relight():
	self.visible = true
	
	if relight_time_left > 0:
		light_radius += light_radius_default / 5.35 / relight_time_left
		$CollisionShape/Light.set_param(3, light_radius)
		
		#Pulse control
		time += (PI / 2.0)
		time += time / relight_time_left
		time -= (PI / 2.0)
		
		relight_time_left -= 1
	
	else:
		#Set light radius to default
		$CollisionShape/Light.set_param(3, light_radius_default)
		lit = true


func extinguish():
	if extinguish_time_left > 0:
		light_radius -= light_radius / extinguish_time_left
		$CollisionShape/Light.set_param(3, light_radius)
		
		#Pulse control
		time -= (PI / 2.0)
		time -= time / extinguish_time_left
		time += (PI / 2.0)
		
		extinguish_time_left -= 1
	else:
		#Set light radius to 0
		$CollisionShape/Light.set_param(3, 0.0)
		lit = false
		
		self.visible = false


func _on_Timer_timeout():
	queue_free()


func _entered_area(area_type, surface_height):
	return


func _exited_area(area_type):
	return


