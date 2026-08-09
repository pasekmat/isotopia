class_name GameEnums
extends RefCounted

## Centrálne enumy pre celý projekt - pridávaj sem nové hodnoty podľa
## potreby. Vďaka class_name sú dostupné odkiaľkoľvek ako
## GameEnums.ItemType.WOOD, GameEnums.CraftingCategory.EQUIPMENT, atď.,
## bez nutnosti čokoľvek importovať.

enum ItemType {
	WOOD,
	STONE,
	FIBER,
	LONGSWORD,
	STONE_PATH
}

enum CraftingCategory {
	MISC,
	POTION,
	EQUIPMENT,
	BUILDING,
}

## Crafting stanice - NONE znamená "dá sa craftovať voľne rukou, bez
## potreby postavenej stanice". Pridávaj ďalšie podľa toho, aké stanice
## postupne pridáš do hry.
enum WorkstationType {
	NONE,
	FURNACE,
	FORGE,
	LEATHERWORKING,
}
