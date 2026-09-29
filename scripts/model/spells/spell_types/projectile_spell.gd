extends SpellType
class_name ProjectileSpell

@export var projectile_scene: PackedScene
@export var projectile_speed: float = 400.0
@export var lifetime: float = 3.0
@export var num_of_projectiles: int = 1
@export var spread_degrees: float = 15.0


func can_cast(_caster: Node2D, _target_position: Vector2, _target_node: Node2D, _spell: BaseSpell) -> bool:
	return projectile_scene != null


func cast_spell(caster: Node2D, target_position: Vector2, _target_node: Node2D, spell: BaseSpell) -> void:
	var base_direction: Vector2 = (target_position - caster.global_position).normalized()

	for i in num_of_projectiles:
		var projectile: Node2D = projectile_scene.instantiate()
		caster.get_parent().add_child(projectile)
		projectile.global_position = caster.global_position

		var offset: float = 0.0
		if num_of_projectiles > 1:
			offset = deg_to_rad(spread_degrees) * (float(i) / (num_of_projectiles - 1) - 0.5)

		projectile.setup(base_direction.rotated(offset), projectile_speed, lifetime, spell, caster)
