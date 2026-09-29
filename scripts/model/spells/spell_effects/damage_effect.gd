extends SpellEffect
class_name DamageEffect

@export var base_damage: int = 10
@export var strength_scaling: float = 0.0
@export var intelligence_scaling: float = 0.0


func apply(caster: Node2D, target: Node2D) -> void:
	if target == null or not target.has_method("take_damage"):
		return

	var total: float = float(base_damage)

	print("Base: ", total)
	if caster.has_method("get_effective_strength"):
		total += caster.get_effective_strength() * strength_scaling
		print("Strength: ", caster.get_effective_strength())
		print("Scaling: ", strength_scaling)

		print("After strength: ", total)

	if caster.has_method("get_effective_intelligence"):
		total += caster.get_effective_intelligence() * intelligence_scaling
		print("After all: ", total)

	target.take_damage(int(round(total)))
