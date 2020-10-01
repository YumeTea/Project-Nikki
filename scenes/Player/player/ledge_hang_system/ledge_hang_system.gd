extends Spatial


signal ledge_grab_point(grab_point_transform, wall_normal_horizontal)


#Node Storage
onready var collider_shape = $Area/CollisionShape.shape
onready var Raycast_Wall = $Area/Raycast_Wall
onready var Raycast_Ledge = $Area/Raycast_Ledge
onready var Raycast_Facing_Wall = $Raycast_Facing_Wall
onready var Raycast_Facing_Ledge = $Raycast_Facing_Ledge
onready var Raycast_Ceiling = $Raycast_Ceiling

#Player State Storage
var state_move

#Transform States
var default_offset = 7.26 #affects how low player rig hangs below ledge
var aerial_offset = 7.27
var swim_offset = 5.58

#Ledge Detection Variables
var wall_angle_min = deg2rad(90)
var ledge_angle_max = deg2rad(45)

var grab_point : Vector3
var facing_direction : Vector3
var grab_point_transform : Transform
var ledge_height : float
var wall_normal : Vector3

#Space Query Variables
var space_rid
var space_state
var query_shape
var intersections : Array

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
					calculate_grab_point(Raycast_Wall, Raycast_Ledge)
				elif on_ledge:
					calculate_grab_point(Raycast_Facing_Wall, Raycast_Facing_Ledge)
					
				break
	else:
		Raycast_Ledge.transform.origin.x = 0.0
		Raycast_Ledge.transform.origin.z = 0.0


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


func get_nearest_intersection():
	return


func position_ledge_raycasts(intersection_idx):
	var cast_to = Raycast_Wall.cast_to
	
	#Move raycasts into position and update them
	Raycast_Wall.cast_to = Vector3(intersections[intersection_idx].x, cast_to.y, intersections[intersection_idx].z)
	Raycast_Ledge.transform.origin.x = intersections[intersection_idx].x
	Raycast_Ledge.transform.origin.z = intersections[intersection_idx].z
	Raycast_Wall.force_raycast_update()
	Raycast_Ledge.force_raycast_update()


func calculate_grab_point(Wall_Normal_Raycast, Ledge_Normal_Raycast):
	var wall_to_ledge_axis
	var ledge_to_wall_axis
	wall_normal = Vector3()
	ledge_height = 0.0
	
	Wall_Normal_Raycast.force_raycast_update()
	Ledge_Normal_Raycast.force_raycast_update()
	
	if Wall_Normal_Raycast.is_colliding() and Ledge_Normal_Raycast.is_colliding() and !Raycast_Ceiling.is_colliding():
		#Estimate wall angle(correct for floating point error)
		var wall_angle = Wall_Normal_Raycast.get_collision_normal().angle_to(Vector3.UP)
		var ledge_angle = Ledge_Normal_Raycast.get_collision_normal().angle_to(Vector3.UP)
		wall_angle = stepify(wall_angle, 0.1)
		ledge_angle = stepify(ledge_angle, 0.1)
		
		#Check if ledge surfaces are within limits
		if wall_angle > wall_angle_min and ledge_angle < ledge_angle_max:
			###GRAB POINT
			#Get axes to rotate wall and ledge vector around
			var cross_wall = Wall_Normal_Raycast.get_collision_normal().cross(Ledge_Normal_Raycast.get_collision_normal()).normalized()
			var cross_ledge = Ledge_Normal_Raycast.get_collision_normal().cross(Wall_Normal_Raycast.get_collision_normal()).normalized()
			
			#Calculate binormals
			var binormal_wall = Wall_Normal_Raycast.get_collision_normal().rotated(cross_wall, deg2rad(90))
			var binormal_ledge = Ledge_Normal_Raycast.get_collision_normal().rotated(cross_ledge, deg2rad(90))
			
			#Find binormal intersections
			var o1 = Wall_Normal_Raycast.get_collision_point()
			var n1 = binormal_wall
			var o2 = Ledge_Normal_Raycast.get_collision_point()
			var n2 = binormal_ledge
			
			var lambda_wall
			
			#Divide by 0 prevention
			if n2.x == 0.0:
				lambda_wall = (0.0 + ((o1.y - o2.y) / n2.y))  /  (0.0 - (n1.y / n2.y))
			elif n2.y == 0.0:
				lambda_wall = (((-o1.x + o2.x) / n2.x) + 0.0)  /  ((n1.x / n2.x) - 0.0)
			else:
				lambda_wall = (((-o1.x + o2.x) / n2.x) + ((o1.y - o2.y) / n2.y))  /  ((n1.x / n2.x) - (n1.y / n2.y))
			
			#Find grab point
			grab_point = o1 + (lambda_wall * n1)
			
			###WALL NORMAL HORIZONTAL
			#Calculate horizontal wall normal
			wall_normal = Wall_Normal_Raycast.get_collision_normal()
			wall_normal.y = 0.0
			wall_normal = wall_normal.normalized()
			
			###GRAB TRANSFORM
			#calculate player facing direction
			facing_direction = Wall_Normal_Raycast.get_collision_normal()
			facing_direction.y = 0.0
			facing_direction = facing_direction.normalized()
			
			#create grab point transform
			grab_point_transform.origin = grab_point
			grab_point_transform = grab_point_transform.looking_at(grab_point + facing_direction, Vector3.UP)
			
			###SIGNAL EMISSION
			#Move grab point visualizer
			$Debug_Nodes/Grab_Point.global_transform.origin = grab_point
			
			emit_signal("ledge_grab_point", grab_point_transform, wall_normal)


func _on_Timer_timeout():
	on_ledge = false


func _on_State_Machine_Move_state_changed(move_state):
	if !(move_state in ["Swim", "Ledge_Hang"]):
		transform.origin.y = aerial_offset
	elif !(move_state in ["Ledge_Hang"]):
		transform.origin.y = swim_offset
	else:
		transform.origin.y = aerial_offset
	
	if move_state == "Ledge_Hang":
		on_ledge = true
	
	state_move = move_state

