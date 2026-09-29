extends CharacterBody2D



const DIRECTIONS: Array[String] = ["e", "se", "s", "sw", "w", "nw", "n", "ne"]

var _facing: String = "s"  # posledný smer - aby idle vedel, kam sa pozerať

@export var speed: float = 150.0
@export var health: int = 670
@export var armor: int = 10
@export var inteligence: int = 10
@export var strength: int = 67
@export var attack_spped: int = 1
@export var stamina: int = 5

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var current_health: int
var _attack_cooldown_remaining: float = 0.0
var _is_attacking: bool = false

var _world_generator: Node  # ChunkedWorldGeneratorV2, nájdené cez skupinu
var _is_jumping: bool = false
var _jump_timer: float = 0.0

const MAX_CLIMB_HEIGHT: int = 1   # o koľko úrovní vyššie sa dá vyliezť skokom
const JUMP_WINDOW: float = 0.3    # ako dlho po stlačení skoku "platí" skok
const JUMP_VISUAL_HEIGHT: float = 50.0
var current_height: int = 0
var _jump_tween: Tween

var occlusion_check_radius: int = 2

@export var mana: int = 100
var current_mana: int

@onready var status_holder: StatusEffectHolder = $StatusEffectHolder

var _spell_cooldowns: Dictionary = {}
var _current_action_anim: String = ""

func _ready() -> void:
	add_to_group("player")
	animated_sprite.play("idle")
	current_health = get_effective_health()
	animated_sprite.animation_finished.connect(_on_animation_finished)
	_world_generator = get_tree().get_first_node_in_group("world_generator")
	current_mana = mana
		
func _on_animation_finished() -> void:
	if animated_sprite.animation == "attack" or animated_sprite.animation == _current_action_anim:
		_is_attacking = false
		_current_action_anim = ""
		

func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("cast_test"):
		print("spell cast")
		try_spell_cast(load("res://scripts/model/spells/concrete_spells/aoe_spell1.tres"))
	
	if status_holder.has_flag("stunned"):
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	var input_vector: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		
	velocity = input_vector * speed * 2 if Input.is_action_pressed("sprint") else input_vector * speed
	if Input.is_action_just_pressed("jump"):
		_jump_timer = JUMP_WINDOW
		_play_jump_visual()
	_jump_timer = max(0.0, _jump_timer - _delta)
	_is_jumping = _jump_timer > 0.0
	
	_apply_terrain_height_blocking(_delta)
	
	move_and_slide()

	_update_animation(input_vector)
	_attack_cooldown_remaining = max(0.0, _attack_cooldown_remaining - _delta)
	_update_height_and_z_index()
	
	for spell_id in _spell_cooldowns.keys():
		_spell_cooldowns[spell_id] = max(0.0, _spell_cooldowns[spell_id] - _delta)

	var base_speed: float = speed * status_holder.get_speed_multiplier()
	velocity = input_vector * base_speed * 2 if Input.is_action_pressed("sprint") else input_vector * base_speed

func _update_animation(input_vector: Vector2) -> void:
	if _is_attacking:
		return

	var moving: bool = input_vector.length() > 0.1
	if moving:
		_facing = _direction_from_vector(input_vector)

	var anim_name: String
	if moving:
		anim_name = "walk_" + _facing
	else:
		var directional_idle: String = "idle_" + _facing
		anim_name = directional_idle if animated_sprite.sprite_frames.has_animation(directional_idle) else "idle"

	if animated_sprite.animation != anim_name:
		animated_sprite.play(anim_name)

func _get_cell_height(world_pos: Vector2) -> int:
	if _world_generator == null:
		return 0

	var cell: Vector2i = _world_generator.tile_map_layer.local_to_map(_world_generator.tile_map_layer.to_local(world_pos))
	return max(_world_generator.terrain.get_height_level(cell.x, cell.y), 0)


func _is_height_blocked(from_height: int, to_height: int) -> bool:
	var diff: int = to_height - from_height
	if diff <= 0:
		return false  # dole/rovno sa dá ísť vždy voľne
	if diff <= MAX_CLIMB_HEIGHT and _is_jumping:
		return false  # skáčeš a rozdiel je zvládnuteľný
	
	return true

func _apply_terrain_height_blocking(delta: float) -> void:
	if velocity == Vector2.ZERO:
		return
	
	var predicted_pos: Vector2 = global_position + velocity * delta
	var predicted_height: int = _get_cell_height(predicted_pos + Vector2(0, current_height * 64))

	if _is_height_blocked(current_height, predicted_height):
		velocity = Vector2.ZERO

func get_effective_health() -> int:
	return health + Equipment.get_total_stat_bonus(GameEnums.StatType.HEALTH)

func get_effective_armor() -> int:
	return armor + Equipment.get_total_stat_bonus(GameEnums.StatType.ARMOR)

func get_effective_intelligence() -> int:
	return inteligence + Equipment.get_total_stat_bonus(GameEnums.StatType.INTELLIGENCE)

func get_effective_strength() -> int:
	return strength + Equipment.get_total_stat_bonus(GameEnums.StatType.STRENGTH)

func get_effective_attack_speed() -> int:
	return attack_spped + Equipment.get_total_stat_bonus(GameEnums.StatType.ATTACK_SPEED)
	

func take_damage(amount: int) -> void:
	
	var actual_damage: int = max(1, amount - get_effective_armor())
	current_health -= actual_damage
	
	if current_health <= 0:
		current_health = 0
		print("Hráč zomrel!")  # TODO: smrť/respawn vyriešime neskôr


func can_attack() -> bool:
	return _attack_cooldown_remaining <= 0.0


func register_attack() -> void:
	_is_attacking = true
	animated_sprite.play("attack")
	var attacks_per_second: float = max(0.1, float(get_effective_attack_speed()))
	_attack_cooldown_remaining = 1.0 / attacks_per_second
	
func _play_jump_visual() -> void:
	if _jump_tween != null and _jump_tween.is_valid():
		_jump_tween.kill()
		animated_sprite.position.y = 0.0

	_jump_tween = create_tween()
	_jump_tween.tween_property(animated_sprite, "position:y", -JUMP_VISUAL_HEIGHT, JUMP_WINDOW / 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_jump_tween.tween_property(animated_sprite, "position:y", 0.0, JUMP_WINDOW / 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


func _update_height_and_z_index() -> void:
	if _world_generator == null:
		return

	current_height = _get_cell_height(global_position + Vector2(0, current_height * 64))

	var cell: Vector2i = _world_generator.tile_map_layer.local_to_map(_world_generator.tile_map_layer.to_local(global_position))
	var max_height: int = current_height
	for dx in range(-2, 2):
		for dy in range(-2, 0):
			var h: int = max(_world_generator.terrain.get_height_level(cell.x + dx, cell.y + dy), 0)
			max_height = max(max_height, h)
	z_index = max_height * 2 + 1


func _direction_from_vector(v: Vector2) -> String:
	# Rozdelí kruh na 8 výsekov po 45° a zaokrúhli na najbližší.
	var index: int = posmod(int(round(v.angle() / (PI / 4.0))), 8)
	return DIRECTIONS[index]
	
	
func try_spell_cast(spell: BaseSpell) -> bool:
	if spell == null or _is_attacking:
		return false

	if status_holder.has_flag("silenced"):
		return false

	if _spell_cooldowns.get(spell.id, 0.0) > 0.0:
		return false

	var mouse_pos: Vector2 = get_global_mouse_position()
	var target: Node2D = _find_target_near(mouse_pos, spell.cast_range)

	if not spell.cast(self, mouse_pos, target):
		return false

	_spell_cooldowns[spell.id] = spell.cooldown

	if spell.cast_animation != "":
		_is_attacking = true
		_current_action_anim = spell.cast_animation
		animated_sprite.play(spell.cast_animation)

	return true


## Najbližšie NPC k bodu - netreba presný klik na nepriateľa.
func _find_target_near(world_pos: Vector2, max_range: float) -> Node2D:
	var closest: Node2D = null
	var closest_dist: float = max_range

	for npc in get_tree().get_nodes_in_group("npc"):
		var dist: float = npc.global_position.distance_to(world_pos)
		if dist < closest_dist:
			closest_dist = dist
			closest = npc

	return closest


func heal(amount: int) -> void:
	current_health = min(current_health + amount, get_effective_health())
