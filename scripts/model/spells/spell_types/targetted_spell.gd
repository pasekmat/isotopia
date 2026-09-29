extends SpellType
class_name TargettedSpell

@export var vfx_scene: PackedScene


func can_cast(caster: Node2D, _target_position: Vector2, target_node: Node2D, spell: BaseSpell) -> bool:
	if target_node == null:
		return false
	return caster.global_position.distance_to(target_node.global_position) <= spell.cast_range


func cast_spell(caster: Node2D, _target_position: Vector2, target_node: Node2D, spell: BaseSpell) -> void:
	spell.apply_effects(caster, target_node)

	if vfx_scene != null:
		var vfx: Node2D = vfx_scene.instantiate()
		if vfx != null:
			caster.get_parent().add_child(vfx)
			vfx.global_position = target_node.global_position
