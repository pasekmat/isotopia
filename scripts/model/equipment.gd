extends Node

signal equipment_changed

## GameEnums.EquipmentSlot -> {"item_id": GameEnums.ItemType, "amount": 1}
## Slot, ktorý nič neobsahuje, jednoducho v tomto Dictionary chýba (nie null).
var equipped: Dictionary = {}


func get_equipped(slot: GameEnums.EquipmentSlot) -> Variant:
	return equipped.get(slot, null)


func is_slot_filled(slot: GameEnums.EquipmentSlot) -> bool:
	return equipped.has(slot)

## Spočíta bonus danej štatistiky zo všetkého momentálne nasadeného gearu.
func get_total_stat_bonus(stat: GameEnums.StatType) -> int:
	var total: int = 0

	for slot in equipped:
		var item: Item = ItemDatabase.get_item(equipped[slot]["item_id"])
		if item == null:
			continue

		match stat:
			GameEnums.StatType.HEALTH:
				total += item.health_bonus
			GameEnums.StatType.ARMOR:
				total += item.armor_bonus
			GameEnums.StatType.INTELLIGENCE:
				total += item.intelligence_bonus
			GameEnums.StatType.STRENGTH:
				total += item.strength_bonus
			GameEnums.StatType.ATTACK_SPEED:
				total += item.attack_speed_bonus

	return total
