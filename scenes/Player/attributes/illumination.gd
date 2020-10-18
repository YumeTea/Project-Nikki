extends Node


signal light_level_changed(light_level)

onready var player_collision = owner.get_node("CollisionShape")
onready var player_radius = owner.get_node("CollisionShape").shape.radius

var nearby_omnilights : Array = []

var light_level : float = 0.0


func _ready():
	emit_signal("light_level_changed", light_level)


func _process(delta):
	update_illumination()


#Raycast currently collides with level and grabbable objects
func update_illumination():
	light_level = 0.0
	
	###Scene light factor
	light_level += Global.get_Scene_Light().light_energy * 100.0
	
	###Omnilight factor
	for light in nearby_omnilights:
		var obstruction = raycast_query(player_collision.global_transform.origin, light.global_transform.origin, light.owner)
		if obstruction.empty():
			var light_range = light.omni_range
			var light_attenuation = light.omni_attenuation
			var light_energy = light.light_energy
			
			var d = player_collision.global_transform.origin.distance_to(light.global_transform.origin) - player_radius
			
			var lit_amount = ((clamp(((light_range - d) / player_radius), -1.0, 1.0) + 1.0) / 2.0) #0 when not in light radius, 1 when fully in light radius
			
			light_level += lit_amount * 100.0
	
	if light_level > 100.0:
		light_level = 100.0
	
	emit_signal("light_level_changed", light_level)


###UTILITY FUNCTIONS###


func raycast_query(from, to, exclude):
	var space_state = owner.get_world().direct_space_state
	var result = space_state.intersect_ray(from, to, [owner, exclude], 0x40001)
	return result


###EXTERNAL USE FUNCTIONS###


func _enter_light(light_node):
	if !(light_node in nearby_omnilights):
		nearby_omnilights.append(light_node)


func _exit_light(light_node):
	nearby_omnilights.remove(nearby_omnilights.find(light_node))













