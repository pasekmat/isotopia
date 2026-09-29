extends SpellEffect
class_name BuffEffect

@export var statuses: Array[StatusEffect] = []

func apply(_caster: Node2D, target: Node2D) -> void:
	if target == null:
		return

	var holder: StatusEffectHolder = _find_holder(target)
	if holder == null:
		return

	for status in statuses:
		holder.apply_status(status)


func _find_holder(target: Node2D) -> StatusEffectHolder:
	for child in target.get_children():
		if child is StatusEffectHolder:
			return child
	return null
