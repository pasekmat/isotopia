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
	WOODEN_WALL
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
	WOODEN_WALL
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

## Equipment sloty - NONE znamená "tento item sa nedá nasadiť ako gear".
enum EquipmentSlot {
	NONE,
	HELMET,
	CLOAK,
	CHEST,
	ARMS,
	PANTS,
	BOOTS,
	MAIN_HAND,
	OFF_HAND,
	TRINKET_1,
	TRINKET_2,
}

enum StatType {
	HEALTH,
	ARMOR,
	INTELLIGENCE,
	STRENGTH,
	ATTACK_SPEED,
	DEXTERITY,
	STAMINA
}

enum NPCBehavior {
	AGGRESSIVE,  # útočí a prenasleduje hráča v dosahu, aj bez provokácie
	NEUTRAL,     # pasívne, kým naň nezaútočíš - potom sa stane agresívne
	PASSIVE,     # nikdy neútočí naspäť, len uteká keď je napadnuté
}

enum NPCState {
	IDLE,
	CHASE,
	ATTACK,
	FLEE,
	DEAD,
}

enum BiomeType{
	FROZEN_SWAMP,
	SWAMPY_TAIGA,
	PINE_FOREST,
	SWAMP,
	JUNGLE,
	
	SNOWY_TUNDRA,
	TAIGA,
	MIXED_FOREST,
	FOREST,
	DENSE_MONSUNE_FOREST,
	
	ROCKY_TUNDRA,
	SPARSE_TAIGA,
	FOREST_STEPPE,
	PLAINS,
	SAVANA,
	
	ICY_DESERT,
	COLD_STEPPE,
	BUSHY_STEPPE,
	STEPPE,
	DRY_STEPPE,
	
	COLD_ROCKY_FIELDS,
	COLD_DESERT,
	ROCKY_DESERT,
	BUSHY_DESERT,
	DESERT,
	
	FROZEN_WATER,
	COLD_WATER,
	WATER,
	WARM_WATER,
	
	BEACH
}	

enum MagicModifier{
	CORRUPTED,
	NORMAL,
	ENCHANTED
}

enum WorldObjectType{
	NONE,
	GRASS,
	BUSH,
	TREE,
	TREESTUMP,
	PEBBLE
}
