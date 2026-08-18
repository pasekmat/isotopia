extends Node

signal blueprint_discovered(blueprint: Blueprint)
signal recipe_unlocked(recipe: Recipe)
signal crafted(recipe: Recipe)
signal category_xp_changed(category: GameEnums.CraftingCategory, current_xp: int, current_level: int)

@export var recipes_folder: String = "res://recipes/"
@export var blueprints_folder: String = "res://blueprints/"
@export var xp_per_level: int = 100

var _recipes_by_id: Dictionary = {}     # GameEnums.RecipeType -> Recipe
var _blueprints_by_id: Dictionary = {}  # GameEnums.BlueprintType -> Blueprint

var _unlocked_recipe_ids: Dictionary = {}      # GameEnums.RecipeType -> true
var _discovered_blueprint_ids: Dictionary = {} # GameEnums.BlueprintType -> true

## Reverzná mapa: GameEnums.RecipeType -> GameEnums.BlueprintType, ktorý ho
## musí najprv odomknúť. Recepty, ktoré tu nie sú, nepotrebujú žiadny
## blueprint - riadia sa len levelom/unlocked_by_default.
var _recipe_required_blueprint: Dictionary = {}

var category_xp: Dictionary = {}    # GameEnums.CraftingCategory -> int
var category_level: Dictionary = {} # GameEnums.CraftingCategory -> int


func _ready() -> void:
	_load_all_recipes()
	_load_all_blueprints()
	_build_reverse_map()

	for id in _recipes_by_id:
		_check_unlock(_recipes_by_id[id])


func _load_all_recipes() -> void:
	var dir := DirAccess.open(recipes_folder)
	if dir == null:
		push_warning("CraftingManager: priečinok '%s' neexistuje." % recipes_folder)
		return

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var recipe: Recipe = load(recipes_folder.path_join(file_name))
			if recipe != null:
				_recipes_by_id[recipe.id] = recipe
		file_name = dir.get_next()
	dir.list_dir_end()

	print("CraftingManager: načítaných %d receptov." % _recipes_by_id.size())


func _load_all_blueprints() -> void:
	var dir := DirAccess.open(blueprints_folder)
	if dir == null:
		push_warning("CraftingManager: priečinok '%s' neexistuje." % blueprints_folder)
		return

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var bp: Blueprint = load(blueprints_folder.path_join(file_name))
			if bp != null and bp.id != GameEnums.BlueprintType.NONE:
				_blueprints_by_id[bp.id] = bp
		file_name = dir.get_next()
	dir.list_dir_end()

	print("CraftingManager: načítaných %d blueprintov." % _blueprints_by_id.size())


func _build_reverse_map() -> void:
	for bp_id in _blueprints_by_id:
		var bp: Blueprint = _blueprints_by_id[bp_id]
		for recipe_id in bp.unlocks_recipe_ids:
			_recipe_required_blueprint[recipe_id] = bp_id


func get_recipe(recipe_id: GameEnums.RecipeType) -> Recipe:
	return _recipes_by_id.get(recipe_id, null)


func get_all_recipes() -> Array:
	return _recipes_by_id.values()


func get_blueprint(blueprint_id: GameEnums.BlueprintType) -> Blueprint:
	return _blueprints_by_id.get(blueprint_id, null)


func is_unlocked(recipe_id: GameEnums.RecipeType) -> bool:
	return _unlocked_recipe_ids.has(recipe_id)


func is_discovered(blueprint_id: GameEnums.BlueprintType) -> bool:
	return _discovered_blueprint_ids.has(blueprint_id)


func get_category_level(category: GameEnums.CraftingCategory) -> int:
	return category_level.get(category, 1)


func get_category_xp(category: GameEnums.CraftingCategory) -> int:
	return category_xp.get(category, 0)


## Zavolaj toto vtedy, keď hráč zoberie/prečíta fyzický blueprint item vo
## svete - pozri Item.grants_blueprint_id.
func discover_blueprint(blueprint_id: GameEnums.BlueprintType) -> void:
	if blueprint_id == GameEnums.BlueprintType.NONE:
		return

	if _discovered_blueprint_ids.has(blueprint_id):
		return

	_discovered_blueprint_ids[blueprint_id] = true

	var bp: Blueprint = get_blueprint(blueprint_id)
	if bp == null:
		return

	blueprint_discovered.emit(bp)

	for recipe_id in bp.unlocks_recipe_ids:
		var recipe: Recipe = get_recipe(recipe_id)
		if recipe != null:
			_check_unlock(recipe)


func can_craft(recipe_id: GameEnums.RecipeType) -> bool:
	var recipe: Recipe = get_recipe(recipe_id)
	if recipe == null or not is_unlocked(recipe_id):
		return false

	for req in recipe.required_items:
		if Inventory.get_item_count(req.item) < req.amount:
			return false

	return true


func craft(recipe_id: GameEnums.RecipeType) -> bool:
	if not can_craft(recipe_id):
		return false

	var recipe: Recipe = get_recipe(recipe_id)

	for req in recipe.required_items:
		Inventory.remove_item(req.item, req.amount)

	Inventory.add_item(recipe.result_item_id, recipe.result_amount)

	_add_category_xp(recipe.category, recipe.xp_reward)
	crafted.emit(recipe)

	return true


func _add_category_xp(category: GameEnums.CraftingCategory, amount: int) -> void:
	var xp: int = category_xp.get(category, 0) + amount
	var level: int = category_level.get(category, 1)

	var leveled_up: bool = false
	while xp >= level * xp_per_level:
		xp -= level * xp_per_level
		level += 1
		leveled_up = true

	category_xp[category] = xp
	category_level[category] = level

	category_xp_changed.emit(category, xp, level)

	if leveled_up:
		for id in _recipes_by_id:
			var recipe: Recipe = _recipes_by_id[id]
			if recipe.category == category:
				_check_unlock(recipe)


## Jediné miesto, kde sa rozhoduje, či je recept reálne craftovateľný -
## kombinuje obe podmienky (prípadný blueprint + level).
func _check_unlock(recipe: Recipe) -> void:
	if _unlocked_recipe_ids.has(recipe.id):
		return

	# NOVÉ: default je GameEnums.BlueprintType.NONE namiesto null - enum
	# nemôže byť null, takže NONE slúži ako "žiadny blueprint nevyžadovaný".
	var required_blueprint_id: GameEnums.BlueprintType = _recipe_required_blueprint.get(recipe.id, GameEnums.BlueprintType.NONE)
	if required_blueprint_id != GameEnums.BlueprintType.NONE and not _discovered_blueprint_ids.has(required_blueprint_id):
		return  # tento recept vyžaduje blueprint, ktorý ešte nebol objavený

	var level: int = get_category_level(recipe.category)
	if recipe.unlocked_by_default or level >= recipe.required_crafting_level:
		_unlocked_recipe_ids[recipe.id] = true
		recipe_unlocked.emit(recipe)
