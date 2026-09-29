extends Resource
class_name SpellType

func can_cast(_caster: Node2D, _target_position: Vector2, _target_node: Node2D, _spell: BaseSpell) -> bool:
	return true

func cast_spell(_caster: Node2D, _target_position: Vector2, _target_node: Node2D, _spell: BaseSpell) -> void:
	pass
