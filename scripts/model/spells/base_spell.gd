extends Resource
class_name BaseSpell

@export var id: String = ""
@export var display_name: String = ""
@export var icon: Texture2D
@export var cooldown: float = 1.0
@export var cast_range: float = 300.0

## Meno animácie, ktorú prehrá KASTUJÚCI (nie kúzlo samotné).
## String, nie referencia - hráč aj vlk si ju prehrajú z vlastného SpriteFrames.
@export var cast_animation: String = "attack"

## Tri osi: kam/na koho to ide, čo to stojí, čo sa stane.
## Efektov môže byť viac - napr. damage + spomalenie + horenie naraz.
@export var spell_type: SpellType
@export var cost: SpellCost
@export var effects: Array[SpellEffect] = []


func cast(caster: Node2D, target_position: Vector2, target_node: Node2D = null) -> bool:
	if spell_type == null:
		return false

	if cost != null and not cost.can_pay(caster):
		return false

	if not spell_type.can_cast(caster, target_position, target_node, self):
		return false

	# Cena sa platí AŽ po overení, že kúzlo naozaj prejde -
	# inak by neúspešný pokus zožral manu.
	if cost != null:
		cost.pay(caster)

	spell_type.cast_spell(caster, target_position, target_node, self)
	return true


## Pomocník pre SpellType - aplikuje všetky efekty na jeden cieľ.
## AoE ho zavolá pre každý zasiahnutý cieľ zvlášť.
func apply_effects(caster: Node2D, target: Node2D) -> void:
	for effect in effects:
		if effect != null:
			effect.apply(caster, target)
