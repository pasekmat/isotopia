class_name Blueprint
extends Resource

## Unikátne ID - toto isté id sa nastavuje aj na Item.grants_blueprint_id
## pri predmete, ktorý tento blueprint reprezentuje vo svete (schéma/kniha/
## zvitok nájdený v lootboxe alebo dropnutý z moba).
@export var id: String = ""

@export var display_name: String = ""
@export var icon: Texture2D
@export_multiline var description: String = ""

## Ktoré recepty tento blueprint odomkne po objavení - jeden blueprint môže
## odomknúť aj viacero receptov naraz (napr. "Príručka kováča Zv. 1" odomkne
## 3 rôzne zbrane).
@export var unlocks_recipe_ids: Array[String] = []
