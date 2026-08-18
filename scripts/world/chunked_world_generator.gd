extends Node2D

@export var tile_map_layer: TileMapLayer
@export var player: Node2D
@export var world_seed: int = 12345
@export var chunk_size: int = 16       # počet dlaždíc na jednu stranu chunku
@export var render_distance: int = 2   # koľko chunkov okolo hráča držať vygenerovaných
@export var unload_distance: int = 4   # od akej vzdialenosti (v chunkoch) sa chunk uvoľní

const ATLAS_SOURCE_ID: int = 1

# --- NOVÉ: spawnovanie objektov ---
@export var tree_scene: PackedScene
@export var stump_scene: PackedScene
@export var pebble_scene: PackedScene
@export var grass_scene: PackedScene
@export var bush_scene: PackedScene

# Kam sa budú spawnuté objekty pridávať ako children.
@export var objects_container: Node2D
# --- koniec novej časti ---

var terrain: TerrainGenerator
var loaded_chunks: Dictionary = {}  # kľúč: Vector2i(chunk_x, chunk_y) -> true
var current_player_chunk: Vector2i = Vector2i(999999, 999999)  # nezmyselný default, aby prvý update prebehol vždy

# NOVÉ: eviduje, ktoré konkrétne inštancie objektov patria ku ktorému
# chunku, aby sme ich vedeli pri uvoľnení chunku zase odstrániť.
var chunk_objects: Dictionary = {}  # kľúč: Vector2i(chunk_x, chunk_y) -> Array[Node2D]


func _ready() -> void:
	terrain = TerrainGenerator.new(world_seed)

	# NOVÉ: ak nemáš objects_container priradený ručne, vytvor si ho sám.
	if objects_container == null:
		objects_container = Node2D.new()
		objects_container.name = "WorldObjects"
		add_sibling.call_deferred(objects_container)


func _process(_delta: float) -> void:
	if player == null or tile_map_layer == null:
		return

	var player_cell: Vector2i = tile_map_layer.local_to_map(tile_map_layer.to_local(player.global_position))
	var player_chunk: Vector2i = Vector2i(
		floori(float(player_cell.x) / chunk_size),
		floori(float(player_cell.y) / chunk_size)
	)

	if player_chunk == current_player_chunk:
		return  # hráč je stále v tom istom chunku, netreba nič prepočítavať

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
			var height_level: int = terrain.get_height_level(x, y)
			var biome: String = terrain.get_biome(x, y)
			var atlas_coords: Vector2i = terrain.get_atlas_coords(height_level, biome)
			tile_map_layer.set_cell(Vector2i(x, y), ATLAS_SOURCE_ID, atlas_coords)

			var object_type: String = terrain.get_object_type(x, y, height_level, biome)
			var cell_state: Dictionary = WorldModifications.get_cell_state(Vector2i(x, y))
			if object_type != "" and cell_state.get("type", "") != "destroyed":
				var instance: ResourceObject = _spawn_object(object_type, Vector2i(x, y))
				if instance != null:
					spawned.append(instance)

	loaded_chunks[chunk_coord] = true
	chunk_objects[chunk_coord] = spawned


func _spawn_object(object_type: String, cell: Vector2i) -> ResourceObject:
	var scene: PackedScene
	match object_type:
		"stump":
			scene = stump_scene
		"tree":
			scene = tree_scene
		"bush":
			scene = bush_scene
		"grass":
			scene = grass_scene
		"pebble":
			scene = pebble_scene

	if scene == null:
		return null

	var instance: ResourceObject = scene.instantiate()

	# NOVÉ poradie: cell sa nastavuje PRED add_child(), aby bola dostupná
	# už v _ready() (potrebné na obnovenie prípadného uloženého stavu
	# poškodenia z WorldModifications). global_position naopak MUSÍ zostať
	# AŽ PO add_child() - inak by sa prepočítala nesprávne (rovnaký problém,
	# aký sme riešili pri pôvodnom bugu s posunutými objektmi).
	instance.cell = cell

	objects_container.add_child(instance)
	instance.global_position = tile_map_layer.to_global(tile_map_layer.map_to_local(cell))

	return instance


func _unload_chunk(chunk_coord: Vector2i) -> void:
	var start_x: int = chunk_coord.x * chunk_size
	var start_y: int = chunk_coord.y * chunk_size

	for x in range(start_x, start_x + chunk_size):
		for y in range(start_y, start_y + chunk_size):
			tile_map_layer.erase_cell(Vector2i(x, y))

	if chunk_objects.has(chunk_coord):
		for obj in chunk_objects[chunk_coord]:
			if is_instance_valid(obj):
				obj.queue_free()
		chunk_objects.erase(chunk_coord)

	loaded_chunks.erase(chunk_coord)
