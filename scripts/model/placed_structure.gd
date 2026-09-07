extends StaticBody2D
class_name PlacedStructure

## Tieto dve hodnoty nastavuje PlacementManager automaticky pri vytvorení -
## nemusíš ich riešiť ručne v editore.
var item_id: GameEnums.ItemType
var cell: Vector2i

@export var highlight_modulate: Color = Color(1.35, 1.35, 1.35)
@export var max_interaction_distance: float = 100.0

@onready var sprite: Sprite2D = $Sprite2D

var _default_modulate: Color
var _tile_highlighter: Node2D
var _player: Node2D
var _is_hovered: bool = false


func _ready() -> void:
	_default_modulate = sprite.modulate
	_tile_highlighter = get_tree().get_first_node_in_group("tile_highlighter")
	_player = get_tree().get_first_node_in_group("player")

	input_pickable = true
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _on_mouse_entered() -> void:
	_is_hovered = true
	sprite.modulate = highlight_modulate
	if _tile_highlighter != null:
		_tile_highlighter.highlight_cell(cell)


func _on_mouse_exited() -> void:
	_is_hovered = false
	sprite.modulate = _default_modulate
	if _tile_highlighter != null:
		_tile_highlighter.clear_highlight()


# "interact" (E), nie "smash" - zobratie naspäť, nie ničenie. Rovnaký
# princíp ako pri Lootbox - input_event nevidí klávesové vstupy, takže sa
# to rieši v _unhandled_input() + hover flag.
func _unhandled_input(event: InputEvent) -> void:
	if not _is_hovered:
		return

	if event.is_action_pressed("interact") and _is_player_in_range():
		pick_up()


func _is_player_in_range() -> bool:
	if _player == null:
		return true

	return global_position.distance_to(_player.global_position) <= max_interaction_distance


func pick_up() -> void:
	Inventory.add_item(item_id, 1)
	WorldModifications.clear_cell_state(cell)
	queue_free()
