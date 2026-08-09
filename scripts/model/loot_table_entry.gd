class_name LootTableEntry
extends Resource

@export var item: GameEnums.ItemType = GameEnums.ItemType.WOOD

@export var min_amount: int = 1
@export var max_amount: int = 1

## Pravdepodobnosť, že sa táto položka v konkrétnej debne vôbec objaví
## (0.0 - 1.0). Napr. 1.0 = vždy, 0.05 = zriedkavý drop.
@export_range(0.0, 1.0) var drop_chance: float = 1.0
