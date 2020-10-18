extends Node


signal spotted_target(target)
###DEBUG SIGNALS###
signal threat_level_changed(threat_level)


var threat_level : float = 0.0

var immediate_distance = 10.0


func _process(delta):
	pass


func threat_increase(target, delta):
	#Light Factor
	threat_level += target.get_node("Attributes/Illumination").light_level * (delta * 2.0)
	
	#Distance Factor
	var target_distance = owner.get_node("CollisionShape").global_transform.origin.distance_to(target.global_transform.origin)
	if target_distance > immediate_distance:
		threat_level -= ((target_distance - immediate_distance) / 10.0) * (delta * 2.0)
		
	#Clamp to 100%
	threat_level = clamp(threat_level, 0.0, 100.0)
	
	emit_signal("threat_level_changed", threat_level)


func threat_decrease(delta):
	threat_level -= 5.0 * (delta * 2.0)
	threat_level = clamp(threat_level, 0.0, 100.0)


###UTILITY FUNCTIONS###


func raycast_query(from, to, exclude):
	var space_state = owner.get_world().direct_space_state
	var result = space_state.intersect_ray(from, to, [owner, exclude])
	return result

