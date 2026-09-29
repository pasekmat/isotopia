extends Node

## Sleduje VŠETKY objekty, nad ktorými je aktuálne kurzor (môže ich byť
## viac naraz, ak sa vizuálne prekrývajú), a rozhoduje, ktorý jeden z nich
## je "navrchu" - len ten sa reálne zvýrazní a reaguje na klik.

var _hovered_objects: Array = []
var _active_object: Node = null


func register_hover(object: Node) -> void:
	if not _hovered_objects.has(object):
		_hovered_objects.append(object)
	_update_active()


func unregister_hover(object: Node) -> void:
	_hovered_objects.erase(object)
	_update_active()


func is_active(object: Node) -> bool:
	return object == _active_object


func _update_active() -> void:
	var new_active: Node = _pick_topmost()

	if new_active == _active_object:
		return

	if _active_object != null and is_instance_valid(_active_object):
		_active_object.set_hover_visual(false)

	_active_object = new_active

	if _active_object != null:
		_active_object.set_hover_visual(true)


# "Navrchu" = vyšší z_index, a pri rovnakom z_index (bežný prípad) väčšie
# global_position.y - presne to isté kritérium, akým Y-sort rozhoduje
# poradie vykresľovania.
func _pick_topmost() -> Node:
	var topmost: Node = null

	for obj in _hovered_objects:
		if not is_instance_valid(obj):
			continue
		if topmost == null:
			topmost = obj
			continue

		if obj.z_index > topmost.z_index:
			topmost = obj
		elif obj.z_index == topmost.z_index and obj.global_position.y > topmost.global_position.y:
			topmost = obj

	return topmost
