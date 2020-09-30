extends KinematicBody

"""
Turn timer on after testing is done
add_child in impact() causes 2 orthonormalize errors
"""


onready var timer = $Timer
onready var impact_burst = null
var impact_effect

#Physics variables
var direction = null
var speed = 1.5
var velocity = Vector3(0,0,0)
var gravity = -9.8
var weight = 0.02

#Item variables
var hit_effect = "fire"
var damage_dealt = 128
var despawn_time = 15

#Interaction Variables
var near_bodies = []


func _ready():
	set_physics_process(false)
	$CollisionRayCast.add_exception(self)
	timer.set_wait_time(despawn_time)
	timer.start(despawn_time)


func start(position_init, direction_init):
	transform = position_init
	direction = direction_init.normalized()
	set_physics_process(true)


func _physics_process(delta):
	if direction:
		arrow_path(delta)
	
	velocity = move_and_collide(velocity)
	
	if $CollisionRayCast.is_colliding():
		impact()


func arrow_path(delta):
	calculate_velocity(delta)


func calculate_velocity(delta):
	###Velocity Calculation
	var temp_velocity = velocity

	var target_velocity = direction * speed
	
	temp_velocity = target_velocity
	
	#Add Gravity
	temp_velocity.y += weight * gravity * delta
	
	###Final Velocity
	velocity = temp_velocity
	
	###Calculate new direction
	direction = velocity / speed


func impact():
	for body in near_bodies:
		#Hit effect type
		if body in get_tree().get_nodes_in_group("actor"):
			body.hit_effect(hit_effect)
		#Damage
		if body in get_tree().get_nodes_in_group("vulnerable"):
			body.take_damage(damage_dealt)
	
	#Hit anim
	if impact_burst:
		impact_effect = impact_burst.instance()
		impact_effect.start($CollisionRayCast.get_collision_point())
		owner.add_child(impact_effect)
	
	queue_free()


func _on_Area_body_entered(body):
	if body in get_tree().get_nodes_in_group("actor"):
		near_bodies.push_front(body)


func _on_Area_body_exited(body):
	if body in get_tree().get_nodes_in_group("actor"):
		near_bodies.erase(body)


func _on_Timer_timeout():
	queue_free()

