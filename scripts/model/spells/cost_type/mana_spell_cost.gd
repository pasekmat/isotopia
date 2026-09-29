extends SpellCost
class_name ManaSpellCost

@export var amount: int = 20

func can_pay(caster: Node2D) -> bool:
	if not "current_mana" in caster:
		return false
	return caster.current_mana >= amount

func pay(caster: Node2D) -> void:
	caster.current_mana -= amount
