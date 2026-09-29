class_name Recipe
extends Resource

@export var id: GameEnums.RecipeType = GameEnums.RecipeType.STONE_PATH
@export var display_name: String = ""

## Suroviny potrebné na craftnutie.
@export var required_items: Array[ItemRequirement] = []

@export var result_item : Item
@export var result_amount: int = 1

## Do ktorej nezávislej crafting kategórie tento recept patrí.
@export var category: GameEnums.CraftingCategory = GameEnums.CraftingCategory.MISC

@export var xp_reward: int = 10

## Ktorú stanicu treba mať postavenú. NONE = dá sa craftovať kdekoľvek.
@export var required_workstation: GameEnums.WorkstationType = GameEnums.WorkstationType.NONE

## Ak true, je odomknutý od úplného začiatku hry.
@export var unlocked_by_default: bool = false

## Od akého levelu v danej `category` sa automaticky odomkne.
@export var required_crafting_level: int = 1

## POZNÁMKA: tento recept môže byť NAVYŠE podmienený objavením konkrétneho
## Blueprint itemu vo svete - to sa ale nerieši tu na recepte, ale
## automaticky vyplýva z toho, či niektorý Blueprint tento recept vo svojom
## zozname "unlocks_recipe_ids" obsahuje. Pozri blueprint.gd.
