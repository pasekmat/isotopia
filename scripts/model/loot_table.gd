class_name LootTable
extends Resource

## Každá položka sa vyhodnocuje NEZÁVISLE (nie je to "vyber jednu z X") -
## debna teda môže dať 0 až všetky položky naraz, podľa ich drop_chance.
## Toto dáva najviac flexibility (napr. "vždy trocha dreva + malá šanca
## na vzácny blueprint" v tej istej debne).
@export var entries: Array[LootTableEntry] = []


## Vygeneruje skutočný loot ako pole {"item_id": GameEnums.ItemType, "amount": int}.
func roll() -> Array:
	var result: Array = []

	for entry in entries:
		if randf() <= entry.drop_chance:
			var amount: int = randi_range(entry.min_amount, entry.max_amount)
			if amount > 0:
				result.append({"item_id": entry.item, "amount": amount})

	return result
