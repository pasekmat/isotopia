class_name TerrainGeneratorV2
extends RefCounted

var elevation_noise: FastNoiseLite
var warmth_noise: FastNoiseLite
var humidity_noise: FastNoiseLite
var magic_noise: FastNoiseLite

var river_noise : FastNoiseLite
var object_noise: FastNoiseLite

var wrld_seed: int
const DECORATION_CATEGORIES := [
	{"chance": 0.2,  "variants": [Vector2i(0, 0)]},  # pebbles
	{"chance": 0.6,  "variants": [Vector2i(1, 0)]},  # grass
	{"chance": 0.05, "variants": [Vector2i(2, 0), Vector2i(3, 0)]}, # molehills7
	{"chance": 0.2, "variants": [Vector2i(0, 1), Vector2i(1, 1)]}, # grassleaves
]

const BUCKET_COUNT: int = 5
const WATER_LEVEL: float = -0.3

const NOISE_THRESHOLDS := [-0.33, -0.11, 0.11, 0.33]

const BIOME_GRID = [
	[GameEnums.BiomeType.FROZEN_SWAMP, GameEnums.BiomeType.SWAMPY_TAIGA, GameEnums.BiomeType.PINE_FOREST, GameEnums.BiomeType.SWAMP, GameEnums.BiomeType.JUNGLE],
	[GameEnums.BiomeType.SNOWY_TUNDRA, GameEnums.BiomeType.TAIGA, GameEnums.BiomeType.MIXED_FOREST, GameEnums.BiomeType.FOREST, GameEnums.BiomeType.DENSE_MONSUNE_FOREST],
	[GameEnums.BiomeType.ROCKY_TUNDRA, GameEnums.BiomeType.SPARSE_TAIGA, GameEnums.BiomeType.FOREST_STEPPE, GameEnums.BiomeType.PLAINS, GameEnums.BiomeType.SAVANA],
	[GameEnums.BiomeType.ICY_DESERT, GameEnums.BiomeType.COLD_STEPPE, GameEnums.BiomeType.BUSHY_STEPPE, GameEnums.BiomeType.STEPPE, GameEnums.BiomeType.DRY_STEPPE],
	[GameEnums.BiomeType.COLD_ROCKY_FIELDS, GameEnums.BiomeType.COLD_DESERT, GameEnums.BiomeType.ROCKY_DESERT, GameEnums.BiomeType.BUSHY_DESERT, GameEnums.BiomeType.DESERT]
]

static var BIOME_COORDS: Dictionary = _build_biome_coords()

func _init(world_seed: int = 0) -> void:
	self.wrld_seed = world_seed
	
	elevation_noise = FastNoiseLite.new()
	elevation_noise.seed = world_seed
	elevation_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	elevation_noise.frequency = 0.005  #vysoke - vela malych jazierok - mozno vhodne na baziny?, nizke - velke vodne plochy, oceany a pod napr. hodnota 0.0005 

	warmth_noise = FastNoiseLite.new()
	warmth_noise.seed = world_seed + 1000  # iný seed než elevation, nech nekopíruje ten istý tvar
	warmth_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	warmth_noise.frequency = 0.001  # biómy sa zvyčajne menia pomalšie/plošnejšie než výška
	
	humidity_noise = FastNoiseLite.new()
	humidity_noise.seed = world_seed + 2000  # iný seed než elevation, nech nekopíruje ten istý tvar
	humidity_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	humidity_noise.frequency = 0.001  # biómy sa zvyčajne menia pomalšie/plošnejšie než výška

	magic_noise = FastNoiseLite.new()
	magic_noise.seed = world_seed + 3000  # iný seed než elevation, nech nekopíruje ten istý tvar
	magic_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	magic_noise.frequency = 0.001  # biómy sa zvyčajne menia pomalšie/plošnejšie než výška

	object_noise = FastNoiseLite.new()
	object_noise.seed = world_seed + 5000
	object_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	object_noise.frequency = 0.15  # vyššia frekvencia = menšie zhluky/škvrny (zoskupenia stromov)
	
	river_noise = FastNoiseLite.new()
	river_noise.seed = world_seed + 10000
	river_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	river_noise.frequency = 0.05  #vysoke - vela malych jazierok - mozno vhodne na baziny?, nizke - velke vodne plochy, oceany a pod napr. hodnota 0.0005 


func get_height_level(x: int, y: int) -> int:
	var height: float = elevation_noise.get_noise_2d(x, y)  # rozsah -1.0 .. 1.0
	if height < WATER_LEVEL:
		return -1
		
	if height <  -0.1:
		return 0
	elif height < 0.1:
		return 1
	elif height < 0.3:
		return 2
	elif height < 0.5:
		return 3
	else:
		return 4

static func _build_biome_coords() -> Dictionary:
	var map := {}
	for h in range(BIOME_GRID.size()):
		for w in range(BIOME_GRID[h].size()):
			map[BIOME_GRID[h][w]] = Vector2i(w, h)
	return map
 
static func find_biome_coords(biome: GameEnums.BiomeType) -> Vector2i:
	return BIOME_COORDS.get(biome, Vector2i(-1, -1))

func get_biome(x: int, y: int) -> Dictionary:
	var humidity: float = humidity_noise.get_noise_2d(x, y)
	var warmth: float = warmth_noise.get_noise_2d(x, y)
	var height_noise: float = elevation_noise.get_noise_2d(x, y)
	var height: int = get_height_level(x,y)
	var magic = magic_noise.get_noise_2d(x,y)
	
	#var is_river = river_noise.get_noise_2d(x,y) > 0.1 and river_noise.get_noise_2d(x,y) < 0.2

	if height == -1:
		return {"Biome" : process_water(warmth), "Magic" : GameEnums.MagicModifier.NORMAL, "Height": height}
	elif height_noise < WATER_LEVEL + 0.01:
		return {"Biome" : GameEnums.BiomeType.BEACH, "Magic" : GameEnums.MagicModifier.NORMAL, "Height": height}

	#if is_river:
		#return {"Biome" : process_water(warmth), "Magic" : GameEnums.MagicModifier.NORMAL, "Height": height}


	var result: Dictionary = process_land_biomes(humidity, warmth, magic)
	result["Height"] = height
	return result

func process_water(warmth: float) -> GameEnums.BiomeType:
	if warmth < -0.33:
		return GameEnums.BiomeType.FROZEN_WATER
	elif warmth < -0.11:
		return GameEnums.BiomeType.COLD_WATER
	elif warmth < 0.33: 
		return GameEnums.BiomeType.WATER
	else:
		return GameEnums.BiomeType.WARM_WATER
	
func process_land_biomes(humidity: float, warmth: float, magic: float) -> Dictionary:
	var biome = get_base_biome(humidity, warmth)
	
	return get_magic_modified_biome(biome, magic)
	
static func get_biome_bucket(value: float) -> int:
	for i in range(NOISE_THRESHOLDS.size()):
		if value < NOISE_THRESHOLDS[i]:
			return i
	return NOISE_THRESHOLDS.size()
	
func get_base_biome(humidity: float, warmth: float) -> GameEnums.BiomeType:
	var h_bucket := get_biome_bucket(humidity)
	var w_bucket := get_biome_bucket(warmth)
	return BIOME_GRID[h_bucket][w_bucket]

func get_magic_modified_biome(biome: GameEnums.BiomeType, magic : float) -> Dictionary:
	var magic_mod = GameEnums.MagicModifier.NORMAL
	if magic < -0.45:
		magic_mod = GameEnums.MagicModifier.CORRUPTED
	elif magic > 0.45:
		magic_mod = GameEnums.MagicModifier.ENCHANTED
		
	return {"Biome" : biome, "Magic" : magic_mod}

func get_atlas_coords(biome: GameEnums.BiomeType) -> Vector2i:
	match biome:
		GameEnums.BiomeType.FROZEN_WATER:
			return Vector2i(5, 0) 
		GameEnums.BiomeType.COLD_WATER:
			return Vector2i(6, 0) 
		GameEnums.BiomeType.WATER:
			return Vector2i(7, 0) 
		GameEnums.BiomeType.WARM_WATER:
			return Vector2i(8, 0)
		GameEnums.BiomeType.BEACH:
			return find_biome_coords(GameEnums.BiomeType.DESERT)
		_:
			return find_biome_coords(biome)

func get_object_type(x: int, y: int, biome: GameEnums.BiomeType) -> GameEnums.WorldObjectType:	
	if biome == GameEnums.BiomeType.FROZEN_WATER or biome == GameEnums.BiomeType.COLD_WATER or biome == GameEnums.BiomeType.WATER or biome == GameEnums.BiomeType.WARM_WATER:
		return GameEnums.WorldObjectType.NONE

	if biome == GameEnums.BiomeType.BEACH:
		return GameEnums.WorldObjectType.NONE

	var density: float = (object_noise.get_noise_2d(x, y) + 1.0) / 2.0  # 0.0 .. 1.0

	if density > 0.2 and density < 0.205:
		return GameEnums.WorldObjectType.COALROCK
	elif density > 0.3 and density < 0.305:
		return GameEnums.WorldObjectType.PEBBLE
	elif density > 0.4 and density < 0.405:
		return GameEnums.WorldObjectType.BUSH
	elif density > 0.5 and density < 0.505:
		return GameEnums.WorldObjectType.ROCK
	elif density > 0.55 and density < 0.555:
		return GameEnums.WorldObjectType.TREE

	return GameEnums.WorldObjectType.NONE

## Vráti pole atlas súradníc - jedna položka na kategóriu (v poradí podľa
## DECORATION_CATEGORIES), Vector2i(-1, -1) = táto kategória tu nie je.
func get_decorations(x: int, y: int, biome: GameEnums.BiomeType) -> Array[Vector2i]:
	var result: Array[Vector2i] = []

	var is_water: bool = biome in [GameEnums.BiomeType.WATER, GameEnums.BiomeType.COLD_WATER,
		GameEnums.BiomeType.FROZEN_WATER, GameEnums.BiomeType.WARM_WATER]

	for i in DECORATION_CATEGORIES.size():
		if is_water:
			result.append(Vector2i(-1, -1))
			continue

		# Deterministická náhoda: rovnaká bunka + kategória = vždy rovnaký výsledok,
		# takže po unloade/reloade chunku budú dekorácie na tom istom mieste.
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(Vector3i(x, y, wrld_seed + 7000 + i))

		var category: Dictionary = DECORATION_CATEGORIES[i]
		if rng.randf() < category["chance"]:
			var variants: Array = category["variants"]
			result.append(variants[rng.randi() % variants.size()])
		else:
			result.append(Vector2i(-1, -1))

	return result
