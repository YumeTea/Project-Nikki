extends Spatial

signal ledge_grab_point(grab_point_transform, ledge_height, wall_normal)

#Node Storage
onready var collider_shape = $Area/CollisionShape.shape
onready var Raycast_Wall = $Area/Raycast_Wall
onready var Raycast_Ledge = $Area/Raycast_Ledge
onready var Raycast_Facing_Wall = $Raycast_Facing_Wall
onready var Raycast_Facing_Ledge = $Raycast_Facing_Ledge
onready var Raycast_Ceiling = $Raycast_Ceiling

#Transform States
var default_offset = 7.26 #affects how low player rig hangs below ledge
var aerial_offset = 7.27
var swim_offset = 5.58

#Ledge Detection Variables
var space_rid
var space_state
var query_shape
var intersections : Array
var grab_point : Vector3
var facing_direction : Vector3

var grab_point_transform : Transform
var ledge_height : float
var wall_normal : Vector3

#Default Values
onready var Raycast_Wall_default_cast_to = Raycast_Wall.cast_to

#Ledge Detection Bools
var object_detected = false
var on_ledge = false


func _ready():
	owner.get_node("State_Machine_Move").connect("move_state_changed", self, "_on_State_Machine_Move_state_changed")
	
	#World Space RID
	space_rid = get_world().space


func _process(delta):
	object_detected = check_object_collisions()
	
	if object_detected:
		for i in intersections.size():
			if intersections[i].z > 0.0: #only consider grab points in front 180 degrees of player
				position_ledge_raycasts(i)
				
				#Calculate grab point differently depending on on ledge or not
				if !on_ledge:
					calculate_grab_point(Raycast_Wall)
				elif on_ledge:
					calculate_grab_point(Raycast_Facing_Wall)
					
				break


func check_object_collisions():
	#World Space RID
	space_rid = get_world().space
	
	#Get PhysicsDirectSpaceState
	space_state = PhysicsServer.space_get_direct_state(space_rid)
	
	#Create shape to query
	query_shape = PhysicsShapeQueryParameters.new()
	query_shape.transform = $Area.global_transform
	query_shape.set_shape(collider_shape)
	query_shape.collision_mask = 0x40000
	
	#Get intersection points on query shape
	intersections = space_state.collide_shape(query_shape)
	
	#Debug Visualizer
	if intersections.size() > 0:
		return true
	else:
		return false


func position_ledge_raycasts(intersection_idx):
	var cast_to = Raycast_Wall.cast_to
	
	#Move raycasts into position and update them
	Raycast_Wall.cast_to = Vector3(intersections[intersection_idx].x, cast_to.y, intersections[intersection_idx].z)
	Raycast_Ledge.transform.origin.x = intersections[intersection_idx].x
	Raycast_Ledge.transform.origin.z = intersections[intersection_idx].z
	Raycast_Wall.force_raycast_update()
	Raycast_Ledge.force_raycast_update()


func calculate_grab_point(Wall_Normal_Raycast):
	wall_normal = Vector3()
	ledge_height = 0.0
	var wall_normal_rotated_up = Vector3()
	
	Wall_Normal_Raycast.force_raycast_update()
	
	#Correct for floating point errors on ledge_normal
	var ledge_normal = Raycast_Ledge.get_collision_normal()
	ledge_normal.x = stepify(ledge_normal.x, 0.0001)
	ledge_normal.y = stepify(ledge_normal.y, 0.0001)
	ledge_normal.z = stepify(ledge_normal.z, 0.0001)
	
	if Wall_Normal_Raycast.is_colliding() and Raycast_Ledge.is_colliding() and ledge_normal == Vector3(0,1,0) and !Raycast_Ceiling.is_colliding():
		wall_normal = Wall_Normal_Raycast.get_collision_normal()
		ledge_height = Raycast_Ledge.get_collision_point().y
		
		# take the cross product and dot product
		var cross = wall_normal.cross(Vector3(0,1,0)).normalized()
		var dot = wall_normal.dot(Vector3(0,1,0))
		
		#rotate wall normal towards y axis by 90 degrees
		wall_normal_rotated_up = wall_normal.rotated(cross, deg2rad(90))
		
		#calculate grab point offset from wall raycast's collision point
		var ledge_height_dif = ledge_height - Wall_Normal_Raycast.get_collision_point().y
		var grab_point_offset = wall_normal_rotated_up * ledge_height_dif
		
		#calculate grab point
		grab_point = Wall_Normal_Raycast.get_collision_point() + grab_point_offset
		
		#calculate player facing direction
		facing_direction = Wall_Normal_Raycast.get_collision_normal()
		facing_direction.y = 0.0
		facing_direction = facing_direction.normalized()
		
		#create grab point transform
		grab_point_transform.origin = grab_point
		grab_point_transform = grab_point_transform.looking_at(grab_point + facing_direction, Vector3(0,1,0))
		
		#Move grab point visualizer
		$Area/Collision_Marker.global_transform.origin = grab_point
		
		emit_signal("ledge_grab_point", grab_point_transform, ledge_height, wall_normal)


func _on_Timer_timeout():
	on_ledge = false


func _on_State_Machine_Move_state_changed(move_state):
	if !(move_state in ["Swim", "Ledge_Hang"]):
		transform.origin.y = aerial_offset
	elif !(move_state in ["Ledge_Hang"]):
		transform.origin.y = swim_offset
	
	if move_state == "Ledge_Hang":
		on_ledge = true

