extends Node2D

@export var tile_map_layer: TileMapLayer
@export var max_placement_distance: float = 150.0

## Kam sa budú pridávať postavené štruktúry. Ak necháš prázdne, vytvorí sa
## automaticky nový Node2D.
@export var placement_container: Node2D

var _tile_highlighter: Node2D
var _player: Node2D


func _ready() -> void:
	_tile_highlighter = get_tree().get_first_node_in_group("tile_highlighter")
	_player = get_tree().get_first_node_in_group("player")

	if placement_container == null:
		placement_container = Node2D.new()
		placement_container.name = "PlacedObjects"
		add_sibling.call_deferred(placement_container)


func _process(_delta: float) -> void:
	# Priebežne zvýrazňuj bunku pod kurzorom, KEĎ hráč drží niečo
	# postaviteľné - vizuálna nápoveda predtým, než reálne klikne.
	var item: Item = _get_selected_placeable_item()

	if item == null or _tile_highlighter == null or tile_map_layer == null:
		if _tile_highlighter != null:
			_tile_highlighter.clear_highlight()
		return

	var cell: Vector2i = _get_cell_under_mouse()
	_tile_highlighter.highlight_cell(cell)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("place"):
		_try_place()


func _get_selected_placeable_item() -> Item:
	var selected: Variant = Inventory.get_selected_item()
	if selected == null:
		return null

	var item: Item = ItemDatabase.get_item(selected["item_id"])
	if item == null or item.placeable_scene == null:
		return null

	return item


func _get_cell_under_mouse() -> Vector2i:
	var mouse_world_pos: Vector2 = get_global_mouse_position()
	return tile_map_layer.local_to_map(tile_map_layer.to_local(mouse_world_pos))


func _try_place() -> void:
	var item: Item = _get_selected_placeable_item()
	if item == null or tile_map_layer == null:
		return

	var cell: Vector2i = _get_cell_under_mouse()
	var cell_world_pos: Vector2 = tile_map_layer.to_global(tile_map_layer.map_to_local(cell))

	# Over vzdialenosť hráča od miesta stavby.
	if _player != null and _player.global_position.distance_to(cell_world_pos) > max_placement_distance:
		return

	# Over, že bunka je voľná (nič tam nie je postavené/zničené/atď.).
	var cell_state: Dictionary = WorldModifications.get_cell_state(cell)
	if cell_state.get("type", "") != "":
		return

	var selected: Variant = Inventory.get_selected_item()
	if not Inventory.remove_item(selected["item_id"], 1):
		return

	var instance: Node2D = item.placeable_scene.instantiate()
	placement_container.add_child(instance)
	instance.global_position = cell_world_pos

	# NOVÉ: ak scéna používa PlacedStructure, nastav jej item_id a cell,
	# aby vedela, čo vrátiť do inventára pri neskoršom zobratí naspäť.
	if instance is PlacedStructure:
		instance.item_id = item.id
		instance.cell = cell

	WorldModifications.set_cell_state(cell, {"type": "placed", "structure_id": item.id})
