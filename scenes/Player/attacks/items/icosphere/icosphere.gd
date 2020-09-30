extends KinematicBody

"""
Turn timer on after testing is done
add_child in impact() causes 2 orthonormalize errors
"""


onready var timer = $Timer
onready var impact_burst = null
var impact_effect #impact animation scene

#Physics variables
var direction = null
var speed = 0.6
var velocity : Vector3
var velocity_horizontal : Vector3
var gravity = -9.8
var weight = 0.08

#Item variables
var hit_effect = null
var damage_dealt = 32
var despawn_time = 15

#Interaction Variables
var near_bodies = [] #used for area of effect impact effects


func _ready():
	set_physics_process(false)
	timer.set_wait_time(despawn_time)
	timer.start(despawn_time)


func start(position_init, direction_init):
	transform = position_init
	direction = direction_init.normalized()
	velocity.y = direction.y * speed
	
	set_physics_process(true)


func _physics_process(delta):
	projectile_path(delta)
	
	var collision = move_and_collide(velocity)
	
	if collision:
		impact(collision.collider)
		


func projectile_path(delta):
	velocity = calculate_velocity(delta)


func calculate_velocity(delta):
	###Velocity Calculation
	var temp_velocity = velocity
	temp_velocity.y = 0.0
	var temp_direction = direction
	direction.y = 0.0
	
	var target_velocity = direction * speed
	
	velocity.y += weight * gravity / 1.5 * delta
	
	temp_velocity.x = target_velocity.x
	temp_velocity.y = velocity.y
	temp_velocity.z = target_velocity.z
	
	return  temp_velocity


func impact(collider):
	#Damage
	if collider in get_tree().get_nodes_in_group("vulnerable"):
		collider.take_damage(damage_dealt)
	
	queue_free()


func _on_Timer_timeout():
	queue_free()

