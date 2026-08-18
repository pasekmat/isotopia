extends Node

signal hotbar_changed

@export var slot_count: int = 8

## Na rozdiel od Inventory sa sem NEautostackuje - hráč presne rozhoduje,
## čo je v ktorom slote (cez drag&drop). null = prázdny slot.
var slots: Array = []  # null alebo {"item_id": GameEnums.ItemType, "amount": int}


func _ready() -> void:
	slots.resize(slot_count)


func get_slot(index: int) -> Variant:
	if index < 0 or index >= slots.size():
		return null
	return slots[index]


func set_slot(index: int, data: Variant) -> void:
	if index < 0 or index >= slots.size():
		return
	slots[index] = data
	hotbar_changed.emit()


func clear_slot(index: int) -> void:
	set_slot(index, null)
