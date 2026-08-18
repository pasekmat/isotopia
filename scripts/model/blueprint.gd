class_name Blueprint
extends Resource

## Vlastný, samostatný enum - NIE ItemType. Pozri poznámku v game_enums.gd.
@export var id: GameEnums.BlueprintType = GameEnums.BlueprintType.NONE

@export var display_name: String = ""
@export var icon: Texture2D
@export_multiline var description: String = ""

## Ktoré recepty tento blueprint odomkne po objavení.
@export var unlocks_recipe_ids: Array[GameEnums.RecipeType] = []
