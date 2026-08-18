extends Node

## Autoload singleton - sleduje ĽUBOVOĽNÉ zmeny, ktoré hráč vykonal na
## konkrétnych bunkách sveta: poškodenie objektu, jeho úplné zničenie,
## neskôr aj hráčom postavené štruktúry. Generátor sa pred spawnutím
## pozrie, či pre danú bunku existuje uložený stav, a podľa neho sa
## zachová namiesto vždy generovať "čerstvý" stav zo šumu.
##
## POZOR: toto je len IN-MEMORY (v pamäti počas behu hry) - na trvalé
## uloženie naprieč reštartmi bude treba tieto dáta neskôr ukladať do
## súboru (save systém) - samostatná téma na neskôr.

var _cell_states: Dictionary = {}  # Vector2i -> Dictionary (ľubovoľné dáta)


## Ulož/aktualizuj stav pre danú bunku. `state` je ľubovoľný Dictionary -
## odporúčam mať v ňom vždy aspoň kľúč "type" (napr. "destroyed", "damaged",
## neskôr "placed"), aby generátor vedel rozlíšiť, ako sa má zachovať.
func set_cell_state(cell: Vector2i, state: Dictionary) -> void:
	_cell_states[cell] = state


## Vráti uložený stav bunky, alebo prázdny Dictionary ak žiadny neexistuje.
## Použi get("type", "") na bezpečné čítanie bez rizika chyby.
func get_cell_state(cell: Vector2i) -> Dictionary:
	return _cell_states.get(cell, {})


func has_cell_state(cell: Vector2i) -> bool:
	return _cell_states.has(cell)


func clear_cell_state(cell: Vector2i) -> void:
	_cell_states.erase(cell)
