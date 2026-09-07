# setup_height_alternatives.gd
# EditorScript - spusti cez Godot menu: File > Run (alebo Ctrl+Shift+X),
# kým je tento súbor otvorený v Script editore.
#
# Pre KAŽDÚ existujúcu dlaždicu v zadanom atlas source vytvorí 4 alternative
# tiles (id 1-4), každú s texture_origin.y posunutým o -HEIGHT_STEP_PX na
# výškovú úroveň. Alternative 0 (základná dlaždica) ostáva nezmenená = height 0.
#
# Uprav si TILESET_PATH a ATLAS_SOURCE_ID podľa svojho projektu pred spustením.
@tool
extends EditorScript

const TILESET_PATH := "res://assets/tiles/new_tile_set.tres"
const ATLAS_SOURCE_ID := 2
const HEIGHT_STEP_PX := 64
const DEFAULT_Y_OFFSET := -32
const MAX_HEIGHT := 4


func _run() -> void:
	var tile_set: TileSet = load(TILESET_PATH)
	if tile_set == null:
		push_error("Nepodarilo sa načítať TileSet na ceste: %s" % TILESET_PATH)
		return

	var source := tile_set.get_source(ATLAS_SOURCE_ID) as TileSetAtlasSource
	if source == null:
		push_error("Atlas source s ID %d neexistuje alebo nie je TileSetAtlasSource." % ATLAS_SOURCE_ID)
		return

	var tiles_count := source.get_tiles_count()
	var created := 0
	var updated := 0

	for i in range(tiles_count):
		var atlas_coords: Vector2i = source.get_tile_id(i)

		for h in range(1, MAX_HEIGHT + 1):
			if not source.has_alternative_tile(atlas_coords, h):
				source.create_alternative_tile(atlas_coords, h)
				created += 1

			var tile_data: TileData = source.get_tile_data(atlas_coords, h)
			tile_data.texture_origin = Vector2i(0, h * HEIGHT_STEP_PX + DEFAULT_Y_OFFSET)
			updated += 1

	print("Hotovo. Dlaždíc v atlase: %d. Novo vytvorených alternatív: %d. Nastavených texture_origin: %d." % [tiles_count, created, updated])
	print("Nezabudni scénu/resource uložiť (Ctrl+S), inak sa zmeny v TileSete nezapíšu na disk.")
