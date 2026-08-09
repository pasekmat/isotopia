extends Node

signal inventory_changed

@export var slot_count: int = 32

## Každý prvok je buď null (prázdny slot), alebo Dictionary
## {"item_id": GameEnums.ItemType, "amount": int}.
var slots: Array = []


func _ready() -> void:
	slots.resize(slot_count)


## Skús pridať item do inventára. Vráti počet kusov, ktoré sa NEZMESTILI
## (0 = všetko sa v poriadku pridalo, >0 = inventár je plný).
func add_item(item_id: GameEnums.ItemType, amount: int) -> int:
	var item: Item = ItemDatabase.get_item(item_id)

	# Ak je toto "blueprint scroll" item, rovno odomkni recept a neuklad
	# ho do bežných slotov - je to jednorazová vec.
	if item != null and item.grants_blueprint_id != "":
		CraftingManager.discover_blueprint(item.grants_blueprint_id)
		return 0

	var max_stack: int = item.max_stack_size if item != null else 99
	var remaining: int = amount

	# Najprv doplň existujúce neplné stacky toho istého itemu.
	for i in slots.size():
		if remaining <= 0:
			break

		var slot = slots[i]
		if slot != null and slot["item_id"] == item_id and slot["amount"] < max_stack:
			var space: int = max_stack - slot["amount"]
			var add_amount: int = min(space, remaining)
			slot["amount"] += add_amount
			remaining -= add_amount

	# Zvyšok ulož do prázdnych slotov (prípadne vo viacerých, ak treba viac stackov).
	for i in slots.size():
		if remaining <= 0:
			break

		if slots[i] == null:
			var add_amount: int = min(max_stack, remaining)
			slots[i] = {"item_id": item_id, "amount": add_amount}
			remaining -= add_amount

	if remaining < amount:
		inventory_changed.emit()

	return remaining


## Odober danému itemu daný počet kusov. Vráti true, ak sa podarilo odobrať
## celé požadované množstvo.
func remove_item(item_id: GameEnums.ItemType, amount: int) -> bool:
	var total_available: int = get_item_count(item_id)
	if total_available < amount:
		return false

	var remaining: int = amount
	for i in slots.size():
		if remaining <= 0:
			break

		var slot = slots[i]
		if slot != null and slot["item_id"] == item_id:
			var take: int = min(slot["amount"], remaining)
			slot["amount"] -= take
			remaining -= take

			if slot["amount"] <= 0:
				slots[i] = null

	inventory_changed.emit()
	return true


## Spočíta koľko kusov daného itemu má hráč celkovo (naprieč všetkými stackmi).
func get_item_count(item_id: GameEnums.ItemType) -> int:
	var total: int = 0
	for slot in slots:
		if slot != null and slot["item_id"] == item_id:
			total += slot["amount"]
	return total
