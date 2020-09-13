extends HBoxContainer

"""
Should maybe have a function to check which item changed or use specific signals
"""

var equipped_items = {}

onready var Arrow_Viewport_Model = $Arrow_Display/Arrow_Viewport/Viewport/Item_Pivot/Arrow_Model
onready var Arrow_Count = $Arrow_Display/Background/Arrow_Count_Background/Arrow_Count
onready var Arrow_Name = $Arrow_Display/Background/Arrow_Name

func _ready():
	#Initialize inventory dicts
	for node in get_tree().get_nodes_in_group("actor"):
		if node.name == "Player":
			equipped_items = node.inventory.equipped_items.duplicate()


func _on_UI_In_Game_equipped_items_changed(equipped_items_dict):
	update_arrow_display(equipped_items_dict)
	
	equipped_items = equipped_items_dict.duplicate()


func update_arrow_display(equipped_items_dict):
	#Update arrow display
		for child in Arrow_Viewport_Model.get_children():
			child.queue_free()
		
		var arrow_model = load(equipped_items_dict["Arrow"].item_reference.model_scene).instance()
		
		Arrow_Viewport_Model.add_child(arrow_model)
		
		Arrow_Count.text = str(equipped_items_dict["Arrow"].quantity)
		Arrow_Name.text = equipped_items_dict["Arrow"].item_reference.name

















