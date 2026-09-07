extends Node2D
class_name ChunkedWorldGeneratorV2


# EXPERIMENTÁLNA verzia ChunkedWorldGeneratorV2 - výška sa rieši cez
# VIACERO TileMapLayer vrstiev (skladanie jednotkových blokov na seba)
# namiesto alternative tiles + texture_origin na jednej zdieľanej vrstve.
# Zvyšok logiky (chunk loading/unloading, spawnovanie objektov,
# WorldModifications) je zámerne identický s ChunkedWorldGeneratorV2.

## Priraď v Inspectore všetkých 5 TileMapLayer child-ov, v poradí od
## najnižšej (index 0) po najvyššiu (index 4) - podľa BUCKET_COUNT v
## TerrainGeneratorV2. Všetky musia mať priradený TEN ISTÝ TileSet resource.
@export var height_layers: Array[TileMapLayer] = []

@export var player: Node2D
@export var world_seed: int = 12345
@export var chunk_size: int = 16       # počet dlaždíc na jednu stranu chunku
@export var render_distance: int = 2   # koľko chunkov okolo hráča držať vygenerovaných
@export var unload_distance: int = 4   # od akej vzdialenosti (v chunkoch) sa chunk uvoľní

const ATLAS_SOURCE_ID: int = 2
const HEIGHT_STEP_PX: int = 64  # rovnaká hodnota ako v ChunkedWorldGeneratorV2

# --- spawnovanie objektov (identické s ChunkedWorldGeneratorV2) ---
@export var tree_scene: PackedScene
@export var stump_scene: PackedScene
@export var pebble_scene: PackedScene
@export var grass_scene: PackedScene
@export var bush_scene: PackedScene

@export var objects_container: Node2D
# --- koniec tejto časti ---

var terrain: TerrainGeneratorV2
var loaded_chunks: Dictionary = {}  # kľúč: Vector2i(chunk_x, chunk_y) -> true
var current_player_chunk: Vector2i = Vector2i(999999, 999999)

var chunk_objects: Dictionary = {}  # kľúč: Vector2i(chunk_x, chunk_y) -> Array[ResourceObject]


func _ready() -> void:
	terrain = TerrainGeneratorV2.new(world_seed)
	_setup_layer_offsets()

	if objects_container == null:
		objects_container = Node2D.new()
		objects_container.name = "WorldObjects"
		add_sibling.call_deferred(objects_container)


# NOVÉ oproti ChunkedWorldGeneratorV2: každá vrstva dostane vizuálny posun
# nahor podľa svojho indexu, a zodpovedajúci z_index, aby sa vyššie vrstvy
# kreslili navrchu tých nižších.
func _setup_layer_offsets() -> void:
	for i in height_layers.size():
		var layer: TileMapLayer = height_layers[i]
		layer.position.y = -HEIGHT_STEP_PX * i
		layer.z_index = i


func _process(_delta: float) -> void:
	if player == null or height_layers.is_empty():
		return

	# height_layers[0] slúži ako referenčná vrstva na prepočet súradníc -
	# má position.y == 0, takže jej lokálny priestor zodpovedá "surovým"
	# svetovým súradniciam bez akéhokoľvek výškového posunu.
	var reference_layer: TileMapLayer = height_layers[0]
	var player_cell: Vector2i = reference_layer.local_to_map(reference_layer.to_local(player.global_position))
	var player_chunk: Vector2i = Vector2i(
		floori(float(player_cell.x) / chunk_size),
		floori(float(player_cell.y) / chunk_size)
	)

	if player_chunk == current_player_chunk:
		return

	current_player_chunk = player_chunk
	_update_chunks(player_chunk)


func _update_chunks(center_chunk: Vector2i) -> void:
	for cx in range(center_chunk.x - render_distance, center_chunk.x + render_distance + 1):
		for cy in range(center_chunk.y - render_distance, center_chunk.y + render_distance + 1):
			var chunk_coord := Vector2i(cx, cy)
			if not loaded_chunks.has(chunk_coord):
				_generate_chunk(chunk_coord)

	var to_unload: Array[Vector2i] = []
	for chunk_coord in loaded_chunks.keys():
		var dist: int = max(absi(chunk_coord.x - center_chunk.x), absi(chunk_coord.y - center_chunk.y))
		if dist > unload_distance:
			to_unload.append(chunk_coord)

	for chunk_coord in to_unload:
		_unload_chunk(chunk_coord)


func _generate_chunk(chunk_coord: Vector2i) -> void:
	var start_x: int = chunk_coord.x * chunk_size
	var start_y: int = chunk_coord.y * chunk_size

	var spawned: Array[ResourceObject] = []

	for x in range(start_x, start_x + chunk_size):
		for y in range(start_y, start_y + chunk_size):
			var cell := Vector2i(x, y)
			var biome_dict: Dictionary = terrain.get_biome(x, y)
			var height: int = max(biome_dict.get("Height"), 0)  # voda (-1) sa kreslí ako 0
			var atlas_coords: Vector2i = terrain.get_atlas_coords(biome_dict.get("Biome"))

			var fill_from: int = _get_fill_start_level(x, y, height)
			for level in range(fill_from, height + 1):
				if level < height_layers.size():
					height_layers[level].set_cell(cell, ATLAS_SOURCE_ID, atlas_coords)

			var object_type: GameEnums.WorldObjectType = terrain.get_object_type(x, y, biome_dict.get("Biome"))
			var cell_state: Dictionary = WorldModifications.get_cell_state(cell)
			if object_type != GameEnums.WorldObjectType.NONE and cell_state.get("type", "") != "destroyed":
				var instance: ResourceObject = _spawn_object(object_type, cell, height)
				if instance != null:
					spawned.append(instance)

	loaded_chunks[chunk_coord] = true
	chunk_objects[chunk_coord] = spawned


func _spawn_object(object_type: GameEnums.WorldObjectType, cell: Vector2i, height: int) -> ResourceObject:
	var scene: PackedScene
	match object_type:
		GameEnums.WorldObjectType.TREESTUMP:
			scene = stump_scene
		GameEnums.WorldObjectType.TREE:
			scene = tree_scene
		GameEnums.WorldObjectType.BUSH:
			scene = bush_scene
		GameEnums.WorldObjectType.GRASS:
			scene = grass_scene
		GameEnums.WorldObjectType.PEBBLE:
			scene = pebble_scene

	if scene == null:
		return null

	var instance: ResourceObject = scene.instantiate()

	# Rovnaké poradie ako v ChunkedWorldGeneratorV2: cell PRED add_child(),
	# global_position AŽ PO.
	instance.cell = cell

	objects_container.add_child(instance)

	# Rovnaký princíp manuálneho height offsetu ako predtým - len teraz
	# počítaný oproti height_layers[0] (bez vlastného posunu) namiesto
	# jedinej zdieľanej vrstvy s alternative tiles.
	var reference_layer: TileMapLayer = height_layers[0]
	instance.global_position = reference_layer.to_global(reference_layer.map_to_local(cell)) - Vector2(0, height * HEIGHT_STEP_PX)

	return instance


func _unload_chunk(chunk_coord: Vector2i) -> void:
	var start_x: int = chunk_coord.x * chunk_size
	var start_y: int = chunk_coord.y * chunk_size

	for x in range(start_x, start_x + chunk_size):
		for y in range(start_y, start_y + chunk_size):
			var cell := Vector2i(x, y)
			# NOVÉ oproti ChunkedWorldGeneratorV2: treba vyčistiť bunku na
			# VŠETKÝCH vrstvách, keďže mohla mať tile na viacerých naraz.
			for layer in height_layers:
				layer.erase_cell(cell)

	if chunk_objects.has(chunk_coord):
		for obj in chunk_objects[chunk_coord]:
			if is_instance_valid(obj):
				obj.queue_free()
		chunk_objects.erase(chunk_coord)

	loaded_chunks.erase(chunk_coord)

func _get_fill_start_level(x: int, y: int, height: int) -> int:
	var min_neighbor_height: int = height
	var neighbor_offsets := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

	for offset in neighbor_offsets:
		var neighbor_height: int = max(terrain.get_height_level(x + offset.x, y + offset.y), 0)
		min_neighbor_height = min(min_neighbor_height, neighbor_height)

	return min_neighbor_height
