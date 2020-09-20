extends Spatial

signal grab_ledge(grab_point_transform, ledge_height)

#Node Storage
onready var collider_shape = $Area/CollisionShape.shape
onready var Raycast_Wall = $Area/Raycast_Wall
onready var Raycast_Ledge = $Area/Raycast_Ledge

#Ledge Detection Variables
var space_rid
var space_state
var query_shape
var intersections : Array
var grab_point : Vector3
var facing_direction : Vector3
var grab_point_transform : Transform

#Ledge Detection Bools
var object_detected = false

func _ready():
	#World Space RID
	space_rid = get_world().space


func _process(delta):
	object_detected = check_object_collisions()
	
	if object_detected:
		if intersections[0].z >= 0:
			var wall_normal = Vector3()
			var wall_normal_rotated_up = Vector3()
			var ledge_height : float
			var cast_to = Raycast_Wall.cast_to
			
			#Move raycasts into position and update them
			Raycast_Wall.cast_to = Vector3(intersections[0].x, cast_to.y, intersections[0].z)
			Raycast_Ledge.transform.origin.x = intersections[0].x
			Raycast_Ledge.transform.origin.z = intersections[0].z
			Raycast_Wall.force_raycast_update()
			Raycast_Ledge.force_raycast_update()
			
			if Raycast_Wall.is_colliding() and Raycast_Ledge.is_colliding():
				wall_normal = Raycast_Wall.get_collision_normal()
				ledge_height = Raycast_Ledge.get_collision_point().y
				
				# take the cross product and dot product
				var cross = wall_normal.cross(Vector3(0,1,0)).normalized()
				var dot = wall_normal.dot(Vector3(0,1,0))
				
				#rotate wall normal towards y axis by 90 degrees
				wall_normal_rotated_up = wall_normal.rotated(cross, deg2rad(90))
				
				#calculate grab point
				var ledge_height_dif = ledge_height - Raycast_Wall.get_collision_point().y
				var grab_point_offset = wall_normal_rotated_up * ledge_height_dif
				
				grab_point = Raycast_Wall.get_collision_point() + grab_point_offset
				
				#calculate player facing direction
				facing_direction = Raycast_Wall.get_collision_normal()
				facing_direction.y = 0.0
				facing_direction = facing_direction.normalized()
				
				#create grab point transform
				grab_point_transform.origin = grab_point
				grab_point_transform = grab_point_transform.looking_at(grab_point + facing_direction, Vector3(0,1,0))
				
				#Move grab point visualizer
				$Area/Collision_Marker.global_transform.origin = grab_point
				
				emit_signal("grab_ledge", grab_point_transform, ledge_height)


func check_object_collisions():
	#World Space RID
	space_rid = get_world().space
	
	#Get PhysicsDirectSpaceState
	space_state = PhysicsServer.space_get_direct_state(space_rid)
	
	#Create shape to query
	query_shape = PhysicsShapeQueryParameters.new()
	query_shape.transform = $Area.global_transform
	query_shape.set_shape(collider_shape)
	
	#Get intersection points on query shape
	intersections = space_state.collide_shape(query_shape)
	
	#Debug Visualizer
	if intersections.size() > 0:
		return true
	else:
		return false












