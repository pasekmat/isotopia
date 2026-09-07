class_name ItemSlotUI
extends Panel

enum SlotKind {
	INVENTORY,  ## číta/zapisuje Inventory.slots[slot_index]
	EQUIPMENT,  ## číta/zapisuje Equipment.equipped[equipment_slot]
}

@export var kind: SlotKind = SlotKind.INVENTORY

## Použije sa len ak kind == INVENTORY.
@export var slot_index: int = 0

## Použije sa len ak kind == EQUIPMENT - určuje AJ ktorý slot, AJ akú
## typovú obmedzenosť (aký equipment_slot musí mať Item, aby sem šiel).
@export var equipment_slot: GameEnums.EquipmentSlot = GameEnums.EquipmentSlot.NONE

@onready var icon: TextureRect = $Icon
@onready var amount_label: Label = $AmountLabel


func refresh() -> void:
	var slot_data = _get_data()

	if slot_data == null:
		icon.texture = null
		amount_label.text = ""
	else:
		var item: Item = ItemDatabase.get_item(slot_data["item_id"])
		icon.texture = item.icon if item != null else null
		amount_label.text = str(slot_data["amount"]) if slot_data["amount"] > 1 else ""


## Vizuálne označí/odznačí tento slot ako aktuálne vybraný (používa HotbarUI).
func set_selected(is_selected: bool) -> void:
	if is_selected:
		modulate = Color(1.3, 1.3, 0.8)
	else:
		modulate = Color.WHITE


func _get_data() -> Variant:
	if kind == SlotKind.INVENTORY:
		return Inventory.slots[slot_index]
	else:
		return Equipment.get_equipped(equipment_slot)


func _set_data(data: Variant) -> void:
	if kind == SlotKind.INVENTORY:
		Inventory.slots[slot_index] = data
		Inventory.inventory_changed.emit()
	else:
		if data == null:
			Equipment.equipped.erase(equipment_slot)
		else:
			Equipment.equipped[equipment_slot] = data
		Equipment.equipment_changed.emit()


func _get_drag_data(_at_position: Vector2) -> Variant:
	var slot_data = _get_data()
	if slot_data == null:
		return null

	var item: Item = ItemDatabase.get_item(slot_data["item_id"])
	var preview := TextureRect.new()
	preview.texture = item.icon if item != null else null
	preview.custom_minimum_size = Vector2(32, 32)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	set_drag_preview(preview)

	return {
		"source_kind": kind,
		"source_slot_index": slot_index,
		"source_equipment_slot": equipment_slot,
	}


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not (data is Dictionary and data.has("source_kind")):
		return false

	# Do equipment slotu smie ísť len item, ktorého equipment_slot presne
	# sedí s týmto slotom (napr. Helmet item len do Helmet slotu).
	if kind == SlotKind.EQUIPMENT:
		var source_data: Variant = _resolve_data(data["source_kind"], data["source_slot_index"], data["source_equipment_slot"])
		if source_data == null:
			return false

		var item: Item = ItemDatabase.get_item(source_data["item_id"])
		if item == null or item.equipment_slot != equipment_slot:
			return false

	return true


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var source_kind: SlotKind = data["source_kind"]
	var source_slot_index: int = data["source_slot_index"]
	var source_equipment_slot: GameEnums.EquipmentSlot = data["source_equipment_slot"]

	var source_data: Variant = _resolve_data(source_kind, source_slot_index, source_equipment_slot)
	var target_data: Variant = _get_data()

	_set_data(source_data)
	_write_data(source_kind, source_slot_index, source_equipment_slot, target_data)


func _resolve_data(source_kind: SlotKind, index: int, eq_slot: GameEnums.EquipmentSlot) -> Variant:
	if source_kind == SlotKind.INVENTORY:
		return Inventory.slots[index]
	else:
		return Equipment.get_equipped(eq_slot)


func _write_data(target_kind: SlotKind, index: int, eq_slot: GameEnums.EquipmentSlot, data: Variant) -> void:
	if target_kind == SlotKind.INVENTORY:
		Inventory.slots[index] = data
		Inventory.inventory_changed.emit()
	else:
		if data == null:
			Equipment.equipped.erase(eq_slot)
		else:
			Equipment.equipped[eq_slot] = data
		Equipment.equipment_changed.emit()
