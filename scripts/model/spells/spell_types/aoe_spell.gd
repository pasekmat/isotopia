extends SpellType
class_name AOESpell

@export var vfx_scene: PackedScene
@export var radius: float = 100.0

## 0 = jednorazový zásah, >0 = zóna, ktorá zostane a tiká.
@export var duration: float = 0.0

## true = okolo kastujúceho, false = na mieste kurzora.
@export var cast_at_caster: bool = false
## Oneskorenie medzi kastnutím a zásahom - čas, kedy sa dá uhnúť.
@export var telegraph_duration: float = 1.0

func can_cast(caster: Node2D, target_position: Vector2, _target_node: Node2D, spell: BaseSpell) -> bool:
	if cast_at_caster:
		return true
	return caster.global_position.distance_to(target_position) <= spell.cast_range


func cast_spell(caster: Node2D, target_position: Vector2, _target_node: Node2D, spell: BaseSpell) -> void:
	var center: Vector2 = caster.global_position if cast_at_caster else target_position

	if vfx_scene == null:
		return

	var zone: Node2D = vfx_scene.instantiate()
	if zone == null:
		return

	caster.get_parent().add_child(zone)
	zone.global_position = center
	zone.setup(radius, duration, spell, caster, telegraph_duration)
