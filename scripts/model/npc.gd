extends CharacterBody2D
class_name NPC

@export var npc_name: String = "Wolf"
@export var behavior: GameEnums.NPCBehavior = GameEnums.NPCBehavior.NEUTRAL

@export var max_health: int = 30
@export var armor: int = 0
@export var damage: int = 5

@export var move_speed: float = 120.0
@export var chase_speed: float = 160.0
@export var flee_speed: float = 180.0

@export var attack_range: float = 40.0
@export var attack_cooldown: float = 1.5

## Ak sa hráč vzdiali viac než toto, NPC ho prestane naháňať/utekať pred ním.
@export var lose_interest_range: float = 400.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea

var current_health: int
var state: GameEnums.NPCState = GameEnums.NPCState.IDLE

var _player: Node2D
var _is_provoked: bool = false  # pre NEUTRAL - stalo sa agresívnym po zásahu
var _attack_timer: float = 0.0

@onready var status_holder: StatusEffectHolder = $StatusEffectHolder


func _ready() -> void:
	current_health = max_health
	_player = get_tree().get_first_node_in_group("player")

	detection_area.body_entered.connect(_on_detection_body_entered)

	input_pickable = true
	input_event.connect(_on_input_event)

	animated_sprite.play("idle")
	add_to_group("npc")

func _physics_process(delta: float) -> void:
	_attack_timer = max(0.0, _attack_timer - delta)

	match state:
		GameEnums.NPCState.IDLE:
			velocity = Vector2.ZERO
		GameEnums.NPCState.CHASE:
			_process_chase()
		GameEnums.NPCState.ATTACK:
			_process_attack()
		GameEnums.NPCState.FLEE:
			_process_flee()
		GameEnums.NPCState.DEAD:
			velocity = Vector2.ZERO

	move_and_slide()
	_update_animation()


func _process_chase() -> void:
	if _player == null:
		state = GameEnums.NPCState.IDLE
		return

	var distance: float = global_position.distance_to(_player.global_position)

	if distance > lose_interest_range:
		state = GameEnums.NPCState.IDLE
		return

	if distance <= attack_range:
		state = GameEnums.NPCState.ATTACK
		return

	velocity = (_player.global_position - global_position).normalized() * chase_speed


func _process_attack() -> void:
	if _player == null:
		state = GameEnums.NPCState.IDLE
		return

	var distance: float = global_position.distance_to(_player.global_position)
	if distance > attack_range:
		state = GameEnums.NPCState.CHASE
		return

	velocity = Vector2.ZERO

	if _attack_timer <= 0.0:
		_attack_timer = attack_cooldown
		if _player.has_method("take_damage"):
			_player.take_damage(max(1, damage))


func _process_flee() -> void:
	if _player == null:
		state = GameEnums.NPCState.IDLE
		return

	var distance: float = global_position.distance_to(_player.global_position)
	if distance > lose_interest_range:
		state = GameEnums.NPCState.IDLE
		return

	velocity = (global_position - _player.global_position).normalized() * flee_speed


func _update_animation() -> void:
	if state == GameEnums.NPCState.DEAD:
		return

	var moving: bool = velocity.length() > 5.0
	var anim_name: String = "walk" if moving else "idle"

	if animated_sprite.animation != anim_name:
		animated_sprite.play(anim_name)

	if velocity.x != 0:
		animated_sprite.flip_h = velocity.x < 0


# Keď hráč VOJDE do detekčného okruhu - AGGRESSIVE začne naháňať hneď,
# NEUTRAL len ak už bolo predtým vyprovokované (pozri take_damage()).
# PASSIVE tu zámerne nič nerobí, reaguje len na zásah.
func _on_detection_body_entered(body: Node2D) -> void:
	if body != _player or state == GameEnums.NPCState.DEAD:
		return

	if behavior == GameEnums.NPCBehavior.AGGRESSIVE:
		state = GameEnums.NPCState.CHASE
	elif behavior == GameEnums.NPCBehavior.NEUTRAL and _is_provoked:
		state = GameEnums.NPCState.CHASE


# Klik na NPC (rovnaký princíp ako ResourceObject - "smash" akcia).
func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if state == GameEnums.NPCState.DEAD or _player == null:
		return

	if event.is_action_pressed("smash"):
		var distance: float = global_position.distance_to(_player.global_position)
		if distance <= attack_range + 20.0 and _player.can_attack():
			_player.register_attack()
			take_damage(_player.get_effective_strength())


func take_damage(amount: int) -> void:
	if state == GameEnums.NPCState.DEAD:
		return

	var actual_damage: int = max(1, amount - armor)
	current_health -= actual_damage
	
	print("Attack dealt. Enemy health: ", current_health)

	if current_health <= 0:
		_die()
		return

	match behavior:
		GameEnums.NPCBehavior.PASSIVE:
			state = GameEnums.NPCState.FLEE
		GameEnums.NPCBehavior.NEUTRAL:
			_is_provoked = true
			state = GameEnums.NPCState.CHASE
		GameEnums.NPCBehavior.AGGRESSIVE:
			state = GameEnums.NPCState.CHASE


func _die() -> void:
	state = GameEnums.NPCState.DEAD
	# TODO: loot drop (podobne ako ResourceObject.depleted), animácia smrti
	queue_free()
	
	
func heal(amount: int) -> void:
	current_health = min(current_health + amount, max_health)
