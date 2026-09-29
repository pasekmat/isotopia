extends Area2D
class_name ResourceObject

## Meno zdroja, len na debug/UI účely.
@export var resource_name: String = "Grass"

## Koľkokrát treba zavolať interact(), kým sa objekt minie/zmizne.
@export var hits_required: int = 1

## Aký item a koľko kusov dá jedno "zaklopanie". Enum namiesto reťazca -
## dropdown v Inspectore, žiadne preklepy.
@export var loot_item_id: GameEnums.ItemType = GameEnums.ItemType.GRASS
@export var loot_amount: int = 1

var hits_remaining: int

signal harvested(resource_object: ResourceObject, item_id: GameEnums.ItemType, amount: int)
signal depleted(resource_object: ResourceObject)


# --- náhodné vizuálne varianty ---
@export var texture_variants: Array[Texture2D] = []
@export var variant_weights: Array[float] = []
@export var collision_scale_variants: Array[float] = []

@onready var sprite: Sprite2D = $Sprite2D
@onready var interaction_shape: CollisionPolygon2D = $CollisionPolygon2D
@onready var occlusion_area: Area2D = $OcclusionArea

@export var occlusion_check_radius: int = 5

@export var highlight_modulate: Color = Color(1.35, 1.35, 1.35)

## Maximálna vzdialenosť (v pixeloch) od hráča, z ktorej ešte funguje interakcia.
@export var max_interaction_distance: float = 100.0

@export var occlusion_fade_alpha: float = 0.5

var _is_occluded: bool = false
var _is_highlighted: bool = false


var _world_generator: Node

var _default_modulate: Color
var _tile_highlighter: Node2D
var _player: Node2D

## Bunka mriežky, na ktorej tento objekt stojí. Nastavuje ju generátor
## priamo pri spawnutí (_spawn_object).
var cell: Vector2i
# --- koniec novej časti ---


func _ready() -> void:
	hits_remaining = hits_required

	# Ak pre túto bunku existuje uložený stav poškodenia (hráč ju predtým
	# čiastočne vyťažil a chunk sa medzičasom unloadol/reloadol), obnov ho.
	var saved_state: Dictionary = WorldModifications.get_cell_state(cell)
	if saved_state.get("type", "") == "damaged":
		hits_remaining = saved_state.get("hits_remaining", hits_required)

	_world_generator = get_tree().get_first_node_in_group("world_generator")
	if _world_generator != null:
		z_index = _compute_z_index()
	else:
		z_index = 1
		
	add_to_group("interactable")
	_apply_random_variant()

	_default_modulate = sprite.modulate
	_tile_highlighter = get_tree().get_first_node_in_group("tile_highlighter")
	_player = get_tree().get_first_node_in_group("player")

	input_pickable = true
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	input_event.connect(_on_input_event)
	occlusion_area.body_entered.connect(_on_occlusion_area_body_entered)
	occlusion_area.body_exited.connect(_on_occlusion_area_body_exited)

func _on_mouse_entered() -> void:
	HoverManager.register_hover(self)


func _on_mouse_exited() -> void:
	HoverManager.unregister_hover(self)


func set_hover_visual(is_hovered: bool) -> void:
	_is_highlighted = is_hovered
	_update_modulate()

	if is_hovered:
		if _tile_highlighter != null:
			_tile_highlighter.highlight_cell(cell)
	else:
		if _tile_highlighter != null:
			_tile_highlighter.clear_highlight()


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event.is_action_pressed("smash") and HoverManager.is_active(self) and _is_player_in_range():
		interact()


func _is_player_in_range() -> bool:
	if _player == null:
		return true  # poistka - ak hráč nie je nájdený (chýba v skupine "player"), nechaj interakciu prejsť

	return global_position.distance_to(_player.global_position) <= max_interaction_distance


func _apply_random_variant() -> void:
	if texture_variants.is_empty():
		return

	var index: int = _pick_variant_index()
	sprite.texture = texture_variants[index]

	if collision_scale_variants.size() == texture_variants.size():
		interaction_shape.scale = Vector2.ONE * collision_scale_variants[index]


func _pick_variant_index() -> int:
	if variant_weights.size() != texture_variants.size():
		return randi() % texture_variants.size()

	var total_weight: float = 0.0
	for weight in variant_weights:
		total_weight += weight

	var roll: float = randf() * total_weight
	var cumulative: float = 0.0
	for i in variant_weights.size():
		cumulative += variant_weights[i]
		if roll <= cumulative:
			return i

	return texture_variants.size() - 1


func interact() -> void:
	if hits_remaining <= 0:
		return

	hits_remaining -= 1
	harvested.emit(self, loot_item_id, loot_amount)
	Inventory.add_item(loot_item_id, loot_amount)

	if hits_remaining <= 0:
		WorldModifications.set_cell_state(cell, {"type": "destroyed"})
		depleted.emit(self)
		_on_mouse_exited()
		queue_free()
	else:
		WorldModifications.set_cell_state(cell, {"type": "damaged", "hits_remaining": hits_remaining})

func _compute_z_index() -> int:
	if resource_name != "Tree" and resource_name != "Rock" and resource_name != "CoalRock" and resource_name != "Bush":
		var height: int = max(_world_generator.terrain.get_height_level(cell.x, cell.y), 0)
		return height * 2 + 1
		
	var max_height: int = 0
	for dx in range(-occlusion_check_radius, occlusion_check_radius + 1):
		for dy in range(-occlusion_check_radius, occlusion_check_radius + 1):
			var h: int = max(_world_generator.terrain.get_height_level(cell.x + dx, cell.y + dy), 0)
			max_height = max(max_height, h)
	return max_height * 2 + 1



func _on_occlusion_area_body_entered(body: Node2D) -> void:
	if body == _player:
		_is_occluded = true
		_update_modulate()


func _on_occlusion_area_body_exited(body: Node2D) -> void:
	if body == _player:
		_is_occluded = false
		_update_modulate()


func _update_modulate() -> void:
	var color: Color = highlight_modulate if _is_highlighted else _default_modulate
	color.a = occlusion_fade_alpha if _is_occluded else 1.0
	sprite.modulate = color
	
	
