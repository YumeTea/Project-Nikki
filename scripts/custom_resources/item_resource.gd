extends Resource
class_name ItemResource

export var name : String
export var index : int
export var removable : bool = true
export var stackable : bool = false
export var max_stack_size : int = 1

var itemtype = [
	"Weapon",
	"Bow",
	"Magic",
	"Arrow",
	"Item",
	"Key",
]
export (String, "Weapon", "Bow", "Magic", "Arrow", "Item", "Key") var type
export (String, FILE) var item_scene
export (String, FILE) var model_scene



















