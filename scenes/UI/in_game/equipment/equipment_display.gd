extends HBoxContainer

"""
Should maybe have a function to check which item changed or use specific signals
"""

var equipped_items = {}

#Arrow Viewport Nodes
onready var Arrow_Viewport_Model = $Arrow_Display/Arrow_Viewport/Viewport/Item_Pivot/Arrow_Model
onready var Arrow_Rotater = $Arrow_Display/Arrow_Viewport/Viewport/Item_Pivot
onready var Arrow_Count = $Arrow_Display/Background/Arrow_Count_Background/Arrow_Count
onready var Arrow_Name = $Arrow_Display/Background/Arrow_Name


func _ready():
	#Initialize inventory dicts
	for node in get_tree().get_nodes_in_group("actor"):
		if node.name == "Player":
			equipped_items = node.inventory.equipped_items.duplicate()
			update_arrow_display(equipped_items)


func _on_UI_In_Game_equipped_items_changed(equipped_items_dict):
	update_arrow_display(equipped_items_dict)
	
	equipped_items = equipped_items_dict.duplicate()


func update_arrow_display(equipped_items_dict):
	#Clear current arrow model view
	for child in Arrow_Viewport_Model.get_children():
		child.queue_free()
	
	if equipped_items_dict["Arrow"]:
		var arrow_model = load(equipped_items_dict["Arrow"].item_reference.model_scene).instance()
		
		Arrow_Viewport_Model.add_child(arrow_model)
		
		Arrow_Count.text = str(equipped_items_dict["Arrow"].quantity)
		Arrow_Name.text = equipped_items_dict["Arrow"].item_reference.name
	else:
		Arrow_Count.text = ""
		Arrow_Name.text = ""
	
	#Begin item rotation and timer
	Arrow_Rotater.get_node("Tween").stop_all()
	Arrow_Rotater.rotate = true
	Arrow_Rotater.get_node("Timer").start(3.5)















