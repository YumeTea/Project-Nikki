extends KinematicBody


signal focus_object_changed(target_object)

#Node Storage
onready var health_node = $Attributes/Health

#World Interaction Variables
var max_fall_height = 34 #should be replaced by max_fall_velocity
var base_fall_damage = 16
var fall_height = 0
var land_height = 0
var is_falling = false

#Input Variables
var input_move_direction : Vector3

#Player Variables
var player_position : Vector3

#Character Flags
var death = false


func _ready():
	for child in $State_Machine_Move.get_children():
		child.connect("position_changed", self, "_on_position_changed")
	for child in $State_Machine_Move.get_children():
		child.connect("started_falling", self, "_on_started_falling")
	for child in $State_Machine_Move.get_children():
		child.connect("landed", self, "_on_landing")


func take_damage(value):
	if !death:
		$AnimationPlayer.play("Damaged")
		health_node.take_damage(value)


func fall_damage():
	var distance_fallen = fall_height - land_height
	var fall_damage = pow(base_fall_damage, (((distance_fallen/max_fall_height)/2.0) + 0.5))
	return fall_damage


func hit_effect(_effect_type):
	return


func _on_position_changed(position):
	player_position = position


func _on_started_falling(height):
	if is_falling == false:
		fall_height = height
		is_falling = true


func _on_landing(height):
	if is_falling == true:
		land_height = height
		var height_difference = fall_height - land_height
		if height_difference > max_fall_height:
			health_node.take_damage(fall_damage())
		is_falling = false

