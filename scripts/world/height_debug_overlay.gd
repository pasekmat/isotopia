extends Node2D
class_name HeightDebugOverlay

## Koľko buniek do každej strany od hráča sa má zobrazovať - viac = väčší
## výkonový náklad (kreslí sa to KAŽDÝ frame), takže drž rozumne malé.
@export var display_radius: int = 8
@export var font_size: int = 16
@export var text_color: Color = Color.RED

var _world_generator: Node
var _player: Node2D
var _font: Font


func _ready() -> void:
	_world_generator = get_tree().get_first_node_in_group("world_generator")
	_player = get_tree().get_first_node_in_group("player")
	_font = ThemeDB.fallback_font

	z_index = 20  # nad úplne všetkým ostatným (terén 0-4, entity 10)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if _world_generator == null or _player == null:
		return

	var reference_layer: TileMapLayer = _world_generator.tile_map_layer
	if reference_layer == null:
		return

	var player_cell: Vector2i = reference_layer.local_to_map(reference_layer.to_local(_player.global_position))

	for x in range(player_cell.x - display_radius, player_cell.x + display_radius):
		for y in range(player_cell.y - display_radius, player_cell.y + display_radius):
			var height: int = max(_world_generator.terrain.get_height_level(x, y), 0)

			var world_pos: Vector2 = reference_layer.to_global(reference_layer.map_to_local(Vector2i(x, y)))
			world_pos -= Vector2(0, height * _world_generator.HEIGHT_STEP_PX)

			var local_pos: Vector2 = to_local(world_pos)
			draw_string(_font, local_pos, str(height), HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, text_color)
			
			var flat_local_pos: Vector2 = to_local(reference_layer.to_global(reference_layer.map_to_local(Vector2i(x, y))))
			flat_local_pos.x += 20  # posun bokom, aby sa nekreslilo cez červené číslo
			draw_string(_font, flat_local_pos, str(height), HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color.BLUE)
