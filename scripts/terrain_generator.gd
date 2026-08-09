class_name TerrainGenerator
extends RefCounted

var elevation_noise: FastNoiseLite
var biome_noise: FastNoiseLite
var object_noise: FastNoiseLite

# Uprav podľa počtu výškových úrovní, ktoré máš pripravené vo svojom
# tileset-e (0 = najnižšia úroveň).
const MAX_HEIGHT_LEVEL: int = 3


func _init(world_seed: int = 0) -> void:
	elevation_noise = FastNoiseLite.new()
	elevation_noise.seed = world_seed
	elevation_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	elevation_noise.frequency = 0.02  # nižšie = pozvoľnejšie kopce/doliny

	biome_noise = FastNoiseLite.new()
	biome_noise.seed = world_seed + 1000  # iný seed než elevation, nech nekopíruje ten istý tvar
	biome_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	biome_noise.frequency = 0.008  # biómy sa zvyčajne menia pomalšie/plošnejšie než výška

	# NOVÉ: samostatná vrstva šumu na rozmiestnenie objektov (stromy, kamene).
	object_noise = FastNoiseLite.new()
	object_noise.seed = world_seed + 2000
	object_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	object_noise.frequency = 0.15  # vyššia frekvencia = menšie zhluky/škvrny (zoskupenia stromov)


func get_height_level(x: int, y: int) -> int:
	var raw: float = elevation_noise.get_noise_2d(x, y)  # rozsah -1.0 .. 1.0
	var normalized: float = (raw + 1.0) / 2.0             # prevod na 0.0 .. 1.0
	var level: int = int(normalized * (MAX_HEIGHT_LEVEL + 1))
	return clampi(level, 0, MAX_HEIGHT_LEVEL)


func get_biome(x: int, y: int) -> String:
	var moisture: float = biome_noise.get_noise_2d(x, y)
	if moisture < -0.7:
		return "sand"
	elif moisture < -0.1:
		return "plains"
	elif moisture < 0.3:
		return "forest"
	else:
		return "water"


func get_atlas_coords(height: int, biome: String) -> Vector2i:
	match biome:
		"sand":
			return Vector2i(5, 0) if height % 2 == 0 else Vector2i(2, 5)
		"plains":
			return Vector2i(0, 0) 
		"forest":
			return Vector2i(2, 2) if height % 2 == 0 else Vector2i(8, 0)
		"water":
			return Vector2i(2, 1) if height % 2 == 0 else Vector2i(7, 4)
		_:
			return Vector2i(2, 1) if height % 2 == 0 else Vector2i(7, 4)


func get_object_type(x: int, y: int, height: int, biome: String) -> String:
	if biome == "water":
		return ""

	var density: float = (object_noise.get_noise_2d(x, y) + 1.0) / 2.0  # 0.0 .. 1.0

	if biome == "forest" and density > 0.69:
		return "tree"
	elif biome == "forest" and density > 0.67:
		return "stump"
	elif biome == "plains" and density > 0.7:
		return "bush"
	elif biome == "plains" and density > 0.69:
		return "grass"
	elif biome == "forest" and density < 0.25:
		return "bush"
	elif biome == "forest" and density < 0.3:
		return "grass"
	elif density > 0.41 and density < 0.415:
		return "pebble"

	return ""
