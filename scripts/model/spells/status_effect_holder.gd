extends Node
class_name StatusEffectHolder

signal status_effects_changed

var _active_statuses : Array[StatusEffect]

var _parent_node : Node2D

func _ready() -> void:
	_parent_node = get_parent()


func apply_status(status: StatusEffect) -> void:
	if status == null:
		return

	if status.refresh_on_reapply:
		for entry in _active_statuses:
			if entry["status"].id == status.id:
				entry["remaining"] = status.duration
				status_effects_changed.emit()
				return

	_active_statuses.append({"status": status, "remaining": status.duration})
	status_effects_changed.emit()


func _process(delta: float) -> void:
	if _active_statuses.is_empty():
		return

	var expired: Array = []

	for entry in _active_statuses:
		entry["remaining"] -= delta

		# Periodický damage/heal - rieši sa priebežne, nie naraz.
		var dps: float = entry["status"].damage_per_second
		if dps != 0.0 and _parent_node != null and _parent_node.has_method("take_damage"):
			_parent_node.take_damage(int(round(dps * delta)))

		if entry["remaining"] <= 0.0:
			expired.append(entry)

	for entry in expired:
		_active_statuses.erase(entry)

	if not expired.is_empty():
		status_effects_changed.emit()


func get_total_stat_bonus(stat: GameEnums.StatType) -> int:
	var total: int = 0

	for entry in _active_statuses:
		var s: StatusEffect = entry["status"]
		match stat:
			GameEnums.StatType.HEALTH:
				total += s.health_bonus
			GameEnums.StatType.ARMOR:
				total += s.armor_bonus
			GameEnums.StatType.INTELLIGENCE:
				total += s.intelligence_bonus
			GameEnums.StatType.STRENGTH:
				total += s.strength_bonus
			GameEnums.StatType.ATTACK_SPEED:
				total += s.attack_speed_bonus

	return total


func get_speed_multiplier() -> float:
	var multiplier: float = 1.0
	for entry in _active_statuses:
		multiplier *= entry["status"].speed_multiplier
	return multiplier


func has_flag(flag: String) -> bool:
	for entry in _active_statuses:
		if flag in entry["status"].flags:
			return true
	return false


func get_active_statuses() -> Array:
	return _active_statuses
