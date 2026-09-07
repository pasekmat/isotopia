extends Control

@onready var panel: PanelContainer = $PanelContainer
@onready var scroll: ScrollContainer = $PanelContainer/ScrollContainer
@onready var list: VBoxContainer = $PanelContainer/ScrollContainer/VBoxContainer

## Ktorú stanicu táto konkrétna UI obsluhuje. NONE = craftenie voľne rukou.
@export var workstation_filter: GameEnums.WorkstationType = GameEnums.WorkstationType.NONE

var _row_nodes: Dictionary = {}  # recipe.id (String) -> HBoxContainer


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	scroll.custom_minimum_size = Vector2(460, 320)

	CraftingManager.recipe_unlocked.connect(_on_recipes_changed)
	Inventory.inventory_changed.connect(_refresh_availability)

	_build_list()

	await get_tree().process_frame
	var viewport_size: Vector2 = get_viewport_rect().size
	panel.position = Vector2(viewport_size.x - panel.size.x - 20, (viewport_size.y - panel.size.y) / 2.0)

	visible = false

func _build_list() -> void:
	for child in list.get_children():
		child.queue_free()
	_row_nodes.clear()

	for recipe in CraftingManager.get_all_recipes():
		if recipe.required_workstation != workstation_filter:
			continue
		if not CraftingManager.is_unlocked(recipe.id):
			continue

		_add_row(recipe)


func _add_row(recipe: Recipe) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(32, 32)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = recipe.icon
	row.add_child(icon)

	var name_label := Label.new()
	name_label.text = recipe.display_name
	name_label.custom_minimum_size = Vector2(110, 0)
	row.add_child(name_label)

	var requirements_box := HBoxContainer.new()
	requirements_box.name = "RequirementsBox"
	requirements_box.custom_minimum_size = Vector2(200, 0)
	requirements_box.add_theme_constant_override("separation", 12)
	row.add_child(requirements_box)

	var craft_button := Button.new()
	craft_button.name = "CraftButton"
	craft_button.text = "Craft"
	craft_button.focus_mode = Control.FOCUS_NONE
	craft_button.pressed.connect(_on_craft_pressed.bind(recipe.id))
	row.add_child(craft_button)

	list.add_child(row)
	_row_nodes[recipe.id] = row

	_build_requirement_icons(recipe, requirements_box)
	_update_row(recipe)


# NOVÉ: postaví ikonku + label pre každú surovinu RAZ (pri vytvorení riadku).
# _update_row() potom len prepisuje text/farbu, nie celú štruktúru.
func _build_requirement_icons(recipe: Recipe, container: HBoxContainer) -> void:
	for req in recipe.required_items:
		var item: Item = ItemDatabase.get_item(req.item)

		var req_box := HBoxContainer.new()
		req_box.add_theme_constant_override("separation", 3)

		var req_icon := TextureRect.new()
		req_icon.custom_minimum_size = Vector2(20, 20)
		req_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		req_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		req_icon.texture = item.icon if item != null else null
		req_box.add_child(req_icon)

		var count_label := Label.new()
		count_label.name = "Count"
		req_box.add_child(count_label)

		container.add_child(req_box)


func _on_craft_pressed(recipe_id: GameEnums.RecipeType) -> void:
	CraftingManager.craft(recipe_id)


func _refresh_availability() -> void:
	for id in _row_nodes:
		var recipe: Recipe = CraftingManager.get_recipe(id)
		if recipe != null:
			_update_row(recipe)


func _update_row(recipe: Recipe) -> void:
	var row: HBoxContainer = _row_nodes.get(recipe.id)
	if row == null:
		return

	var requirements_box: HBoxContainer = row.get_node("RequirementsBox")
	var craft_button: Button = row.get_node("CraftButton")

	for i in recipe.required_items.size():
		var req: ItemRequirement = recipe.required_items[i]
		var have: int = Inventory.get_item_count(req.item)

		var req_box: HBoxContainer = requirements_box.get_child(i)
		var count_label: Label = req_box.get_node("Count")
		count_label.text = "%d/%d" % [have, req.amount]

		# NOVÉ: zelená ak máš dosť, červená ak nie - rýchly vizuálny prehľad.
		if have >= req.amount:
			count_label.add_theme_color_override("font_color", Color(0.5, 0.9, 0.5))
		else:
			count_label.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))

	craft_button.disabled = not CraftingManager.can_craft(recipe.id)


func _on_recipes_changed(_recipe: Recipe) -> void:
	_build_list()
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_crafting"):
		visible = not visible
