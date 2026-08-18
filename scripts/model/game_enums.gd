class_name GameEnums
extends RefCounted

enum ItemType {
	WOOD,
	STONE,
	GRASS,

	HAY,
	RAW_IRON,
	RAW_GOLD,
	RAW_COPPER,
	RAW_SILVER,

	IRON,
	GOLD,
	SILVER,
	COPPER,
	BRONZE,

	LONGSWORD,
	STONE_PATH,

	## Toto je FYZICKÝ predmet (schéma/zvitok), ktorý sa dá lootnúť a nosiť
	## v inventári - nie samotný blueprint. Loot tabuľky ho používajú
	## rovnako ako akýkoľvek iný item.
	LONGSWORD_BP,
}

enum CraftingCategory {
	MISC,
	POTION,
	EQUIPMENT,
	BUILDING,
}

enum WorkstationType {
	NONE,
	FURNACE,
	FORGE,
	LEATHERWORKING,
}

enum RecipeType {
	STONE_PATH,
	LONGSWORD,
}

## Samostatný enum pre samotné blueprinty (odomykacie "kľúče"), oddelený od
## ItemType - fyzický predmet (napr. LONGSWORD_BP vyššie) len ODKAZUJE na
## hodnotu z tohto enumu cez Item.grants_blueprint_id.
##
## NONE je dôležitý sentinel - keďže enum nemôže byť null, NONE reprezentuje
## "žiadny blueprint" všade tam, kde by si predtým použil null/"".
enum BlueprintType {
	NONE,
	LONGSWORD,
}
