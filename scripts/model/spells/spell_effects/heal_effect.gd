extends SpellEffect
class_name HealEffect

@export var base_heal: int = 20
@export var intelligence_scaling: float = 0.5


func apply(caster: Node2D, target: Node2D) -> void:
	if target == null or not target.has_method("heal"):
		return

	var total: float = float(base_heal)
	if caster.has_method("get_effective_intelligence"):
		total += caster.get_effective_intelligence() * intelligence_scaling

	target.heal(int(round(total)))
