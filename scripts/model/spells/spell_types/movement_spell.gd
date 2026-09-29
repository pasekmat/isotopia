extends SpellType
class_name MovementSpell

@export var distance: float = 200.0
@export var duration: float = 0.15
@export var toward_cursor: bool = true  # false = v smere, kam sa postava pozerá
@export var trail_scene: PackedScene


func cast_spell(caster: Node2D, target_position: Vector2, _target_node: Node2D, spell: BaseSpell) -> void:
	var direction: Vector2

	if toward_cursor:
		direction = (target_position - caster.global_position).normalized()
	elif "_facing" in caster:
		direction = _direction_from_facing(caster._facing)
	else:
		direction = Vector2.RIGHT

	if trail_scene != null:
		var trail: Node2D = trail_scene.instantiate()
		caster.get_parent().add_child(trail)
		trail.global_position = caster.global_position

	# Tween namiesto okamžitého presunu - inak by sa postava teleportovala.
	var tween: Tween = caster.create_tween()
	tween.tween_property(caster, "global_position",
		caster.global_position + direction * distance, duration) \
		.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)

	# Efekty sa môžu aplikovať na seba - napr. dash, ktorý dá krátku nezraniteľnosť.
	spell.apply_effects(caster, caster)


func _direction_from_facing(facing: String) -> Vector2:
	match facing:
		"e": return Vector2.RIGHT
		"se": return Vector2(1, 1).normalized()
		"s": return Vector2.DOWN
		"sw": return Vector2(-1, 1).normalized()
		"w": return Vector2.LEFT
		"nw": return Vector2(-1, -1).normalized()
		"n": return Vector2.UP
		"ne": return Vector2(1, -1).normalized()
	return Vector2.DOWN
