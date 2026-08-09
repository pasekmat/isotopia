extends Label

## Pretiahni sem svoj Player node.
@export var player: Node2D

## Voliteľné - ak priradíš, zobrazí sa aj súradnica bunky (cell), nielen
## surová svetová (pixelová) pozícia.
@export var tile_map_layer: TileMapLayer


func _process(_delta: float) -> void:
	if player == null:
		text = "Player nie je priradený"
		return

	var world_pos: Vector2 = player.global_position
	var lines: Array[String] = []

	if tile_map_layer != null:
		var cell: Vector2i = tile_map_layer.local_to_map(tile_map_layer.to_local(world_pos))
		lines.append("Cell: (%d, %d)" % [cell.x, cell.y])

	text = "\n".join(lines)
