extends Resource
class_name StatusEffect

@export var id : String

@export_group("StatusMods")
@export var health_bonus : float
@export var armor_bonus : float
@export var speed_bonus : float
@export var strength_bonus : float
@export var attack_speed_bonus : float
@export var stamina_bonus : float

@export_group("StatusFlags")
@export var flags : Array[GameEnums.StatusEffectFlagId]

@export_group("DOTStatusEffect")
@export var damage_per_second : float = 0
