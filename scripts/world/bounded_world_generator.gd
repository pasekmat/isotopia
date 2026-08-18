extends TileMapLayer

@export var world_seed: int = 12345
@export var world_width: int = 64   # počet dlaždíc v smere X
@export var world_height: int = 64  # počet dlaždíc v smere Y

# Zisti skutočné ID svojho atlas source-u v TileSet editore a uprav.
const ATLAS_SOURCE_ID: int = 0

var terrain: TerrainGenerator


func _ready() -> void:
	terrain = TerrainGenerator.new(world_seed)
	generate_world()


func generate_world() -> void:
	var half_w: int = world_width / 2
	var half_h: int = world_height / 2

	for x in range(-half_w, half_w):
		for y in range(-half_h, half_h):
			var height_level: int = terrain.get_height_level(x, y)
			var biome: String = terrain.get_biome(x, y)
			var atlas_coords: Vector2i = terrain.get_atlas_coords(height_level, biome)
			set_cell(Vector2i(x, y), ATLAS_SOURCE_ID, atlas_coords)
