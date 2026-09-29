extends CollisionObject2D
class_name PlacedStructure

## Tieto dve hodnoty nastavuje PlacementManager automaticky pri vytvorení -
## nemusíš ich riešiť ručne v editore.
var item_id: GameEnums.ItemType
var cell: Vector2i

@export var highlight_modulate: Color = Color(1.35, 1.35, 1.35)
@export var max_interaction_distance: float = 100.0

@export var occlusion_fade_alpha: float = 0.5
@export var occlusion_radius: float = 60.0

var _is_occluded: bool = false
var _is_highlighted: bool = false

@onready var sprite: Sprite2D = $Sprite2D

var _default_modulate: Color
var _tile_highlighter: Node2D
var _player: Node2D
var _is_hovered: bool = false

var occlusion_check_radius = 2
var _world_generator: Node

func _ready() -> void:
	_default_modulate = sprite.modulate
	_tile_highlighter = get_tree().get_first_node_in_group("tile_highlighter")
	_player = get_tree().get_first_node_in_group("player")
	_world_generator = get_tree().get_first_node_in_group("world_generator")

	input_pickable = true
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	z_index = _compute_z_index()

func _on_mouse_entered() -> void:
	_is_hovered = true
	_update_modulate()
	if _tile_highlighter != null:
		_tile_highlighter.highlight_cell(cell)


func _on_mouse_exited() -> void:
	_is_hovered = false
	_update_modulate()
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


func _compute_z_index() -> int:
		
	var max_height: int = 0
	for dx in range(-occlusion_check_radius, occlusion_check_radius + 1):
		for dy in range(-occlusion_check_radius, occlusion_check_radius + 1):
			var h: int = max(_world_generator.terrain.get_height_level(cell.x + dx, cell.y + dy), 0)
			max_height = max(max_height, h)
	return max_height * 2 + 1

func _process(_delta: float) -> void:
	if _player == null:
		return

	var in_front: bool = global_position.y > _player.global_position.y
	var near: bool = global_position.distance_to(_player.global_position) <= occlusion_radius

	var was_occluded: bool = _is_occluded
	_is_occluded = in_front and near

	if _is_occluded != was_occluded:
		_update_modulate()


func _update_modulate() -> void:
	var color: Color = highlight_modulate if _is_hovered else _default_modulate
	color.a = occlusion_fade_alpha if _is_occluded else 1.0
	sprite.modulate = color
