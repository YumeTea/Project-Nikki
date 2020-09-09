extends GridContainer

func _ready():
	GameManager.connect("player_initialized", self, "_on_Player_initialized")
	
	
func _on_Player_initialized(player):
	player.inventory.connect("inventory_changed", self, "_on_Player_inventory_changed")


func _on_Player_inventory_changed(inventory):
	for node in get_children():
		node.queue_free() #clear inventory display
		
	for item in inventory.get_items():
		var item_label = Label.new()
		item_label.text = "%s x%d" % [item.item_reference.name, item.quantity] #%d for second string?
		add_child(item_label)










