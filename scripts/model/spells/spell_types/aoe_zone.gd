extends Area2D
class_name AoeZone

## Ako často tikne trvajúca zóna (v sekundách).
@export var tick_interval: float = 1.0


@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

var _radius: float = 100.0
var _duration: float = 0.0
var _spell: BaseSpell
var _caster: Node2D
var _tick_timer: float = 0.0


var _telegraph: float = 0.0

func setup(radius: float, duration: float, spell: BaseSpell, caster: Node2D, telegraph: float) -> void:
	_radius = radius
	_duration = duration
	_spell = spell
	_caster = caster
	_telegraph = telegraph

	# Všetko, čo bolo doteraz v _ready() - teraz sa spustí až tu, keď
	# máme skutočné hodnoty. Volajúci musí setup() zavolať po add_child(),
	# aby @onready premenné (sprite, collision) už existovali.
	z_index = 20

	var shape := CircleShape2D.new()
	shape.radius = _radius
	collision.shape = shape

	if sprite.texture != null:
		var sprite_diameter: float = sprite.texture.get_width() * sprite.scale.x
		if sprite_diameter > 0.0:
			sprite.scale *= (_radius * 2.0) / sprite_diameter

	if _telegraph > 0.0:
		sprite.modulate.a = 0.35
		var tween: Tween = create_tween().set_loops()
		tween.tween_property(sprite, "modulate:a", 0.7, 0.25)
		tween.tween_property(sprite, "modulate:a", 0.35, 0.25)

		await get_tree().create_timer(_telegraph).timeout
		tween.kill()
		sprite.modulate.a = 1.0

	await get_tree().physics_frame
	_apply_to_targets()

	if _duration <= 0.0:
		await get_tree().create_timer(0.3).timeout
		queue_free()

func _process(delta: float) -> void:
	if _duration <= 0.0:
		return

	_duration -= delta
	if _duration <= 0.0:
		queue_free()
		return

	_tick_timer -= delta
	if _tick_timer <= 0.0:
		_tick_timer = tick_interval
		_apply_to_targets()


func _apply_to_targets() -> void:
	if _spell == null:
		return

	var bodies: Array = get_overlapping_bodies()
	print("V zóne nájdených telies: ", bodies.size())
	
	for body in get_overlapping_bodies():
		if body == _caster:
			continue
		_spell.apply_effects(_caster, body)
