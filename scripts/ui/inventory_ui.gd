extends Control

@export var columns: int = 5
@export var slot_size: Vector2 = Vector2(48, 48)

@onready var panel: PanelContainer = $PanelContainer
@onready var grid: GridContainer = $PanelContainer/GridContainer

var _slot_nodes: Array[Panel] = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # NOVÉ: nech neblokuje kliky na svet mimo panelu

	grid.columns = columns
	_build_slots()

	Inventory.inventory_changed.connect(_refresh)
	_refresh()

	# NOVÉ: počkaj frame, nech má panel reálne vypočítanú svoju veľkosť
	# (keďže sloty vytvárame dynamicky, veľkosť nie je známa hneď), potom
	# ho explicitne vycentruj podľa skutočnej veľkosti obrazovky.
	await get_tree().process_frame
	var viewport_size: Vector2 = get_viewport_rect().size
	panel.position = (viewport_size - panel.size) / 2.0
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_inventory"):
		visible = not visible


# Vytvorí toľko "políčok" inventára, koľko má Inventory slotov - dynamicky,
# takže sa netreba spoliehať na ručné poukladanie v editore.
func _build_slots() -> void:
	for i in Inventory.slot_count:
		var slot_panel := Panel.new()
		slot_panel.custom_minimum_size = slot_size
		slot_panel.clip_contents = true  # NOVÉ: orežte čokoľvek, čo by presahovalo hranice slotu

		var icon := TextureRect.new()
		icon.name = "Icon"
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		slot_panel.add_child(icon)

		var label := Label.new()
		label.name = "AmountLabel"
		# NOVÉ: label vyplní celý slot (rovnako ako icon), a o vizuálne
		# umiestnenie čísla do pravého dolného rohu sa postará zarovnanie
		# textu - nie pozícia/veľkosť samotného Control node-u.
		label.set_anchors_preset(Control.PRESET_FULL_RECT)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		label.add_theme_font_size_override("font_size", 14)  # NOVÉ: pevná, menšia veľkosť písma
		slot_panel.add_child(label)

		grid.add_child(slot_panel)
		_slot_nodes.append(slot_panel)


func _refresh() -> void:
	for i in Inventory.slots.size():
		if i >= _slot_nodes.size():
			break

		var slot_data = Inventory.slots[i]
		var icon: TextureRect = _slot_nodes[i].get_node("Icon")
		var label: Label = _slot_nodes[i].get_node("AmountLabel")

		if slot_data == null:
			icon.texture = null
			label.text = ""
		else:
			var item: Item = ItemDatabase.get_item(slot_data["item_id"])
			icon.texture = item.icon if item != null else null
			label.text = str(slot_data["amount"]) if slot_data["amount"] > 1 else ""
