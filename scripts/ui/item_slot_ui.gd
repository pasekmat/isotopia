class_name ItemSlotUI
extends Panel

## Index do Inventory.slots - hotbar aj inventár teraz čítajú/zapisujú
## do TOHO ISTÉHO poľa, len HotbarUI zobrazuje prvých pár indexov aj
## v samostatnom paneli dole na obrazovke.
@export var slot_index: int = 0

@onready var icon: TextureRect = $Icon
@onready var amount_label: Label = $AmountLabel


func refresh() -> void:
	var slot_data = Inventory.slots[slot_index]

	if slot_data == null:
		icon.texture = null
		amount_label.text = ""
	else:
		var item: Item = ItemDatabase.get_item(slot_data["item_id"])
		icon.texture = item.icon if item != null else null
		amount_label.text = str(slot_data["amount"]) if slot_data["amount"] > 1 else ""


func _get_drag_data(_at_position: Vector2) -> Variant:
	var slot_data = Inventory.slots[slot_index]
	if slot_data == null:
		return null

	var item: Item = ItemDatabase.get_item(slot_data["item_id"])
	var preview := TextureRect.new()
	preview.texture = item.icon if item != null else null
	preview.custom_minimum_size = Vector2(32, 32)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	set_drag_preview(preview)

	return {"source_index": slot_index}


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("source_index")


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var source_index: int = data["source_index"]

	var source_data: Variant = Inventory.slots[source_index]
	var target_data: Variant = Inventory.slots[slot_index]

	Inventory.slots[slot_index] = source_data
	Inventory.slots[source_index] = target_data
	Inventory.inventory_changed.emit()
