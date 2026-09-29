extends SpellCost
class_name HealthSpellCost

@export var amount: int = 10

## Ostro väčšie - kúzlom sa nesmieš zabiť.
func can_pay(caster: Node2D) -> bool:
	if not "current_health" in caster:
		return false
	return caster.current_health > amount

func pay(caster: Node2D) -> void:
	caster.current_health -= amount
