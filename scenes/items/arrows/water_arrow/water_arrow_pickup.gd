extends Area

export var item_name : String #should be item in item database

var mesh_nodepath = "Arrow_Mesh"


func interact():
	Global.get_Player().inventory.add_item(item_name, 1)
	queue_free()

