extends Area2D
class_name Lootbox

@export var loot_table: LootTable
@export var max_interaction_distance: float = 100.0
@export var highlight_modulate: Color = Color(1.35, 1.35, 1.35)

## Voliteľné - iný sprite pre "už otvorenú" debnu (prázdna/pootvorená).
## Ak necháš prázdne, sprite sa po otvorení nezmení, len prestane reagovať.
@export var opened_texture: Texture2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var interaction_shape: CollisionShape2D = $CollisionShape2D

## Bunka mriežky, na ktorej debna stojí. Pre ručne umiestnené debny si to
## nastav priamo v Inspectore; pre procedurálne spawnuté (cez generátor,
## rovnako ako stromy/kamene) to nastaví generátor sám.
@export var cell: Vector2i = Vector2i.ZERO

signal opened(lootbox: Lootbox)

var _default_modulate: Color
var _tile_highlighter: Node2D
var _player: Node2D
var _is_opened: bool = false
var _is_hovered: bool = false  # NOVÉ: sledované cez mouse_entered/exited


func _ready() -> void:
	_default_modulate = sprite.modulate
	_tile_highlighter = get_tree().get_first_node_in_group("tile_highlighter")
	_player = get_tree().get_first_node_in_group("player")

	var saved_state: Dictionary = WorldModifications.get_cell_state(cell)
	if saved_state.get("type", "") == "opened":
		_apply_opened_visual()

	input_pickable = true
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	z_index = 10


func _on_mouse_entered() -> void:
	_is_hovered = true  # NOVÉ

	if _is_opened:
		return

	sprite.modulate = highlight_modulate
	if _tile_highlighter != null:
		_tile_highlighter.highlight_cell(cell)


func _on_mouse_exited() -> void:
	_is_hovered = false  # NOVÉ

	sprite.modulate = _default_modulate
	if _tile_highlighter != null:
		_tile_highlighter.clear_highlight()


# Klávesové "interact" (E) sa chytá tu (input_event vidí len myš/touch).
# Netreba mať kurzor nad debnou - stačí byť v dosahu (_is_player_in_range).
# Hover (_is_hovered) sa naďalej používa len na vizuálne zvýraznenie vyššie,
# nie ako podmienka pre samotné otvorenie.
func _unhandled_input(event: InputEvent) -> void:
	if _is_opened:
		return

	if event.is_action_pressed("interact") and _is_player_in_range():
		open()


func _is_player_in_range() -> bool:
	if _player == null:
		return true

	return global_position.distance_to(_player.global_position) <= max_interaction_distance


## Otvor debnu - rozdá loot z tabuľky do Inventory a debna sa označí ako
## vyčerpaná (aj naprieč unload/reload vďaka WorldModifications).
func open() -> void:
	if _is_opened or loot_table == null:
		return

	_is_opened = true

	for drop in loot_table.roll():
		Inventory.add_item(drop["item_id"], drop["amount"])

	WorldModifications.set_cell_state(cell, {"type": "opened"})
	opened.emit(self)
	_apply_opened_visual()


func _apply_opened_visual() -> void:
	_is_opened = true
	sprite.modulate = _default_modulate

	if opened_texture != null:
		sprite.texture = opened_texture

	input_pickable = false  # už sa na ňu nedá znova kliknúť
