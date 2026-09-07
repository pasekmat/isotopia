extends CharacterBody2D

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

func _ready() -> void:
	animated_sprite.play("idle")
	current_health = get_effective_health()
	animated_sprite.animation_finished.connect(_on_animation_finished)
	_world_generator = get_tree().get_first_node_in_group("world_generator")
	z_index = 10
	
	queue_redraw()
	
func _on_animation_finished() -> void:
	if animated_sprite.animation == "attack":
		_is_attacking = false
		

func _physics_process(_delta: float) -> void:
	# Input.get_vector potrebuje, aby si mal v Project Settings -> Input Map
	# vytvorené akcie: move_left (A), move_right (D), move_up (W), move_down (S)
	# TODO: pohyb na zaklade delty?
	var input_vector: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		
	velocity = input_vector * speed * 2 if Input.is_action_pressed("sprint") else input_vector * speed
	if Input.is_action_just_pressed("jump"):
		_jump_timer = JUMP_WINDOW
	_jump_timer = max(0.0, _jump_timer - _delta)
	_is_jumping = _jump_timer > 0.0

	_apply_terrain_height_blocking(_delta)
	
	move_and_slide()

	_update_animation(input_vector)
	_attack_cooldown_remaining = max(0.0, _attack_cooldown_remaining - _delta)


func _update_animation(input_vector: Vector2) -> void:
	if _is_attacking:
		return
		
	var moving: bool = input_vector.length() > 0.1
	var anim_name: String

	if moving:
		anim_name = "walk"
	else:
		anim_name = "idle"

	# play() volaj len keď sa animácia skutočne mení, inak sa reštartuje
	# každý frame od prvej snímky a vyzerá to "trhavo".
	if animated_sprite.animation != anim_name:
		animated_sprite.play(anim_name)

	# Keďže zatiaľ nemáš samostatné animácie pre každý z 8 smerov, aspoň
	# prevrátenie sprite-u podľa horizontálneho smeru dá hráčovi vizuálnu
	# spätnú väzbu, že sa pozerá doľava/doprava.
	if input_vector.x != 0:
		animated_sprite.flip_h = input_vector.x < 0

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

	var current_height: int = _get_cell_height(global_position)

	# X a Y sa kontrolujú SAMOSTATNE, aby hráč mohol "kĺzať" pozdĺž útesu
	# pri diagonálnom pohybe namiesto úplného zastavenia.
	var predicted_x: Vector2 = global_position + Vector2(velocity.x, 0) * delta
	if _is_height_blocked(current_height, _get_cell_height(predicted_x)):
		velocity.x = 0

	var predicted_y: Vector2 = global_position + Vector2(0, velocity.y) * delta
	if _is_height_blocked(current_height, _get_cell_height(predicted_y)):
		velocity.y = 0
		
		
# --------------------------------------------------------------------------
# Keď neskôr pridáš samostatné animácie pre všetkých 8 smerov (idle_0..idle_7,
# walk_0..walk_7), napíš mi a vrátime sa k smerovej verzii skriptu, ktorú
# prepína animáciu podľa uhla pohybu namiesto len flip_h.
# --------------------------------------------------------------------------

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
	
	print(current_health)

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

func _draw() -> void:
	draw_circle(Vector2.ZERO, 20, Color.BLUE)
