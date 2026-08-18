extends Control

## Koľko PRVÝCH slotov z Inventory.slots sa zobrazí v hotbare (0 až
## hotbar_slot_count - 1). Musí byť <= Inventory.slot_count.
@export var hotbar_slot_count: int = 8

@export var slot_size: Vector2 = Vector2(48, 48)
@export var item_slot_scene: PackedScene

@onready var panel: PanelContainer = $PanelContainer
@onready var row: HBoxContainer = $PanelContainer/HBoxContainer

var _slot_nodes: Array[ItemSlotUI] = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_build_slots()

	# NOVÉ: rovnaký signál ako InventoryUI, keďže ide o tie isté dáta.
	Inventory.inventory_changed.connect(_refresh)
	_refresh()

	await get_tree().process_frame
	var viewport_size: Vector2 = get_viewport_rect().size
	panel.position = Vector2(
		(viewport_size.x - panel.size.x) / 2.0,
		viewport_size.y - panel.size.y - 20
	)


func _build_slots() -> void:
	for i in hotbar_slot_count:
		var slot: ItemSlotUI = item_slot_scene.instantiate()
		slot.slot_index = i  
		slot.custom_minimum_size = slot_size
		row.add_child(slot)
		_slot_nodes.append(slot)


func _refresh() -> void:
	for slot in _slot_nodes:
		slot.refresh()
