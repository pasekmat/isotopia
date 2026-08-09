extends Node

## Priečinok, kde budeš mať uložené .tres súbory jednotlivých Item resources.
@export var items_folder: String = "res://items/"

var _items_by_id: Dictionary = {}  # GameEnums.ItemType -> Item


func _ready() -> void:
	_load_all_items()


func _load_all_items() -> void:
	var dir := DirAccess.open(items_folder)
	if dir == null:
		push_warning("ItemDatabase: priečinok '%s' neexistuje. Vytvor si ho a pridaj doň Item .tres súbory." % items_folder)
		return

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var item: Item = load(items_folder.path_join(file_name))
			if item != null:
				if _items_by_id.has(item.id):
					push_warning("ItemDatabase: viacero .tres súborov má rovnaké id '%s' - over si %s." % [GameEnums.ItemType.keys()[item.id], file_name])
				_items_by_id[item.id] = item
		file_name = dir.get_next()
	dir.list_dir_end()

	print("ItemDatabase: načítaných %d predmetov." % _items_by_id.size())


## Vráti Item podľa jeho id, alebo null ak preň neexistuje .tres súbor.
func get_item(item_id: GameEnums.ItemType) -> Item:
	return _items_by_id.get(item_id, null)
