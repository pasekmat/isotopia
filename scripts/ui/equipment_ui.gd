extends Control

@export var slot_size: Vector2 = Vector2(48, 48)
@export var item_slot_scene: PackedScene

@onready var panel: PanelContainer = $PanelContainer
@onready var list: VBoxContainer = $PanelContainer/MainLayout/VBoxContainer
@onready var stats_list: VBoxContainer = $PanelContainer/MainLayout/StatsList

var _slot_nodes: Dictionary = {}  # GameEnums.EquipmentSlot -> ItemSlotUI

const SLOT_LABELS: Dictionary = {
	GameEnums.EquipmentSlot.HELMET: "Helmet",
	GameEnums.EquipmentSlot.CLOAK: "Cloak",
	GameEnums.EquipmentSlot.CHEST: "Chest",
	GameEnums.EquipmentSlot.ARMS: "Arms",
	GameEnums.EquipmentSlot.PANTS: "Pants",
	GameEnums.EquipmentSlot.BOOTS: "Boots",
	GameEnums.EquipmentSlot.MAIN_HAND: "Main Hand",
	GameEnums.EquipmentSlot.OFF_HAND: "Off Hand",
	GameEnums.EquipmentSlot.TRINKET_1: "Trinket 1",
	GameEnums.EquipmentSlot.TRINKET_2: "Trinket 2",
}

var _player: Node2D
var _stat_labels: Dictionary = {}

var _hp_label: Label

const STAT_NAMES: Dictionary = {
	"Health": GameEnums.StatType.HEALTH,
	"Armor": GameEnums.StatType.ARMOR,
	"Intelligence": GameEnums.StatType.INTELLIGENCE,
	"Strength": GameEnums.StatType.STRENGTH,
	"Attack Speed": GameEnums.StatType.ATTACK_SPEED,
}


func _process(_delta: float) -> void:
	_refresh_stats()
	

func _build_stats_display() -> void:
	_hp_label = Label.new()
	stats_list.add_child(_hp_label)
	
	for stat_name in STAT_NAMES:
		var label := Label.new()
		stats_list.add_child(label)
		_stat_labels[stat_name] = label
	
	
func _refresh_stats() -> void:
	if _player == null:
		return

	_hp_label.text = "HP: %d / %d" % [_player.current_health, _player.get_effective_health()]
	_stat_labels["Health"].text = "Health: %d" % _player.get_effective_health()
	_stat_labels["Armor"].text = "Armor: %d" % _player.get_effective_armor()
	_stat_labels["Intelligence"].text = "Intelligence: %d" % _player.get_effective_intelligence()
	_stat_labels["Strength"].text = "Strength: %d" % _player.get_effective_strength()
	_stat_labels["Attack Speed"].text = "Attack Speed: %d" % _player.get_effective_attack_speed()

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_build_slots()

	Equipment.equipment_changed.connect(_refresh)
	_refresh()

	await get_tree().process_frame
	var viewport_size: Vector2 = get_viewport_rect().size
	panel.position = Vector2(20, (viewport_size.y - panel.size.y) / 2.0)
	
	_player = get_tree().get_first_node_in_group("player")
	_build_stats_display()
	_refresh_stats()
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_equipment"):
		visible = not visible


func _build_slots() -> void:
	for slot_enum in SLOT_LABELS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)

		var label := Label.new()
		label.text = SLOT_LABELS[slot_enum]
		label.custom_minimum_size = Vector2(90, 0)
		row.add_child(label)

		var slot: ItemSlotUI = item_slot_scene.instantiate()
		slot.kind = ItemSlotUI.SlotKind.EQUIPMENT
		slot.equipment_slot = slot_enum
		slot.custom_minimum_size = slot_size
		row.add_child(slot)

		list.add_child(row)
		_slot_nodes[slot_enum] = slot


func _refresh() -> void:
	for slot_enum in _slot_nodes:
		_slot_nodes[slot_enum].refresh()
	
	_refresh_stats()
