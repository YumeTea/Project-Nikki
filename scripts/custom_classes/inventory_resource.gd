extends Resource
class_name Inventory

"""
Change setget notation when that is updated
export equipped items?
"""

signal inventory_changed(inventory_resource)
signal equipped_items_changed(equipped_items)

export var _items = Array() setget set_items, get_items
var equipped_items = {
	"Weapon": null,
	"Bow": null,
	"Magic": null,
	"Arrow": null,
	"Item": null,
}
var inventory = {
	"Weapon": [],
	"Bow": [],
	"Magic": [],
	"Arrow": [],
	"Item": [],
}


func set_items(new_items):
	_items = new_items
	emit_signal("inventory_changed", self)


func get_items():
	return _items


func get_item(index_value):
	return _items[index_value]


func add_item(item_name, quantity):
	if quantity <= 0:
		print("attempted to add negative amount of item")
		return
	
	#Assign item's resource to item variable
	var item = ItemDatabase.get_item(item_name)
	if not item:
		print("item not in ItemDatabase")
		return
	
	var remaining_quantity = quantity
	var max_stack_size = item.max_stack_size if item.stackable else 1
	
	
	if item.stackable:
		for i in range(_items.size() - 1):
			if remaining_quantity == 0: #for multiple stacks/only taking part of an item's stack
				break #stops looping and moves on
			
			var added_item = _items[i]
			
			if added_item.item_reference.name != item.name: #keep looping until item is found in items
				continue #goes to next iteration of loop
			
			if added_item.quantity < max_stack_size:
				var current_quantity = added_item.quantity
				added_item.quantity = min(current_quantity + remaining_quantity, max_stack_size)
				remaining_quantity = 0 #For inventory items that player can only have one stack of
				
				#Update inventory/equipped quantity
				update_item_quantity(added_item, added_item.quantity)
	
	
	#Handling for new items and empty inventory
	if remaining_quantity > 0:
		var new_item = {
			item_reference = item,
			quantity = min(remaining_quantity, max_stack_size),
		}
		_items.append(new_item)
		inventory[new_item.item_reference.type].append(new_item)
		remaining_quantity = 0
		
		#Update inventory/equipped quantity and re sort item type
		update_item_quantity(new_item, new_item.quantity)
		inventory[new_item.item_reference.type].sort_custom(self, "sort_item_type")
	
	emit_signal("inventory_changed", self)



func remove_item(item_name, quantity):
	if quantity < 0:
		print("tried to remove a negative amount of items")
		return
	
	var remaining_quantity = quantity
	
	#Look for item in array of all held items and remove it if found
	for i in (_items.size() - 1):
		if item_name == _items[i].item_reference.name and _items[i].item_reference.removable == true:
			var removed_item = _items[i]
			
			var current_quantity = removed_item.quantity
			removed_item.quantity = max(current_quantity - remaining_quantity, 0)
			remaining_quantity = 0
			
			#Update inventory/equipped quantity
			update_item_quantity(removed_item, removed_item.quantity)
			
			#Remove item from inventory if depleted
			if removed_item.quantity == 0:
				equip_item(removed_item.item_reference.type + "_None")
				_items.remove(i)
			
	emit_signal("inventory_changed", self)


func sort_item_type(item_a, item_b):
	if item_a.item_reference.index < item_b.item_reference.index:
		return true
	return false


func update_item_quantity(item, quantity):
	for i in (inventory[item.item_reference.type].size() - 1):
		if inventory[item.item_reference.type][i].item_reference == item.item_reference:
			inventory[item.item_reference.type][i].quantity = quantity
			#Update item in equipped items if it's equipped
			if equipped_items[item.item_reference.type] != null:
				if equipped_items[item.item_reference.type].item_reference == item.item_reference:
					equipped_items[item.item_reference.type].quantity = quantity


func equip_item(item_name): #returns true if item is possessed and can be equipped
	for i in _items.size():
		if item_name == _items[i].item_reference.name:
			equipped_items[_items[i].item_reference.type] = _items[i]
			emit_signal("equipped_items_changed", equipped_items)
			return true
	return false


func next_item(item_type):
	var current_item = equipped_items[item_type]
	var next_item_slot = inventory[item_type].find(current_item) + 1
	if next_item_slot < inventory[item_type].size():
		equip_item(inventory[item_type][next_item_slot].item_reference.name)
	else:
		equip_item(inventory[item_type][0].item_reference.name)


func previous_item(item_type):
	var current_item = equipped_items[item_type]
	var previous_item_slot = inventory[item_type].find(current_item) - 1
	if previous_item_slot >= 0:
		equipped_items[item_type] = inventory[item_type][previous_item_slot]
	else:
		equipped_items[item_type] = inventory[item_type][inventory[item_type].size() - 1]

