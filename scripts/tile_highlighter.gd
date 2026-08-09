extends Node2D

## Pretiahni sem svoj TileMapLayer node.
@export var tile_map_layer: TileMapLayer
@export var highlight_color: Color = Color(1.0, 1.0, 0.2, 0.35)  # výplň (poloпriehľadná)
@export var line_width: float = 2.0

var current_cell: Vector2i = Vector2i(999999, 999999)
var is_highlight_visible: bool = false


func _ready() -> void:
	# Rovnaký princíp ako pri GridOverlay - z_index má prioritu nad Y-sortom,
	# takže sa zvýraznenie vykreslí spoľahlivo navrchu dlaždíc.
	z_index = 1
	y_sort_enabled = false

	# Pridaj sa do skupiny, aby ťa vedeli ResourceObject-y nájsť automaticky.
	add_to_group("tile_highlighter")


## Zavolaj z ResourceObject pri mouse_entered.
func highlight_cell(cell: Vector2i) -> void:
	if cell == current_cell and is_highlight_visible:
		return  # už zvýraznená tá istá bunka, netreba prekresľovať

	current_cell = cell
	is_highlight_visible = true
	queue_redraw()


## Zavolaj z ResourceObject pri mouse_exited.
func clear_highlight() -> void:
	if not is_highlight_visible:
		return

	is_highlight_visible = false
	queue_redraw()


func _draw() -> void:
	if not is_highlight_visible or tile_map_layer == null or tile_map_layer.tile_set == null:
		return

	var half_size: Vector2 = Vector2(tile_map_layer.tile_set.tile_size) / 2.0

	# Prevod cez to_global/to_local, aby to fungovalo nezávisle od toho, kde
	# presne v strome scény tento node sedí (rovnaký princíp ako pri GridOverlay).
	var center: Vector2 = to_local(tile_map_layer.to_global(tile_map_layer.map_to_local(current_cell)))

	var top: Vector2 = center + Vector2(0, -half_size.y)
	var right: Vector2 = center + Vector2(half_size.x, 0)
	var bottom: Vector2 = center + Vector2(0, half_size.y)
	var left: Vector2 = center + Vector2(-half_size.x, 0)

	var points := PackedVector2Array([top, right, bottom, left])
	draw_colored_polygon(points, highlight_color)

	var outline_color := Color(highlight_color.r, highlight_color.g, highlight_color.b, 1.0)
	draw_polyline([top, right, bottom, left, top], outline_color, line_width)
