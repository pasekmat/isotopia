class_name Item
extends Resource

## Unikátne ID predmetu.
@export var id: GameEnums.ItemType = GameEnums.ItemType.WOOD

@export var display_name: String = ""
@export var icon: Texture2D
@export var max_stack_size: int = 99
@export_multiline var description: String = ""

## Ak je toto nastavené (na iné ako NONE), tento item reprezentuje fyzicky
## nájdenú "schému/recept" - pri zobratí do inventára sa rovno odomkne
## príslušný blueprint (CraftingManager.discover_blueprint) a item sa
## NEULOŽÍ do inventára ako bežný predmet (je to jednorazová vec).
@export var grants_blueprint_id: GameEnums.BlueprintType = GameEnums.BlueprintType.NONE

## Ak je toto nastavené (na iné ako NONE), tento item sa dá nasadiť ako
## gear do príslušného equipment slotu.
@export var equipment_slot: GameEnums.EquipmentSlot = GameEnums.EquipmentSlot.NONE

## Ak je toto vyplnené, tento item sa dá "postaviť" do sveta (cez
## PlacementManager) - priraď scénu s vizuálom + prípadnou kolíziou
## postavenej štruktúry.
@export var placeable_scene: PackedScene

@export_group("Stat Bonuses")
@export var health_bonus: int = 0
@export var armor_bonus: int = 0
@export var intelligence_bonus: int = 0
@export var strength_bonus: int = 0
@export var attack_speed_bonus: int = 0
