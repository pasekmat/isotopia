extends Area2D
class_name SpellProjectile

var _direction: Vector2 = Vector2.RIGHT
var _speed: float = 400.0
var _lifetime: float = 3.0
var _spell: BaseSpell
var _caster: Node2D


func setup(direction: Vector2, speed: float, lifetime: float, spell: BaseSpell, caster: Node2D) -> void:
	_direction = direction
	_speed = speed
	_lifetime = lifetime
	_spell = spell
	_caster = caster


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	z_index = 20


func _physics_process(delta: float) -> void:
	global_position += _direction * _speed * delta

	_lifetime -= delta
	if _lifetime <= 0.0:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body == _caster:
		return

	if _spell != null:
		_spell.apply_effects(_caster, body)

	queue_free()
