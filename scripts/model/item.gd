class_name Item
extends Resource

## Unikátne ID predmetu - teraz enum namiesto reťazca, takže si vyberáš
## z dropdownu v Inspectore namiesto písania textu (žiadne preklepy).
## Nové typy predmetov pridávaš do GameEnums.ItemType.
@export var id: GameEnums.ItemType = GameEnums.ItemType.WOOD

@export var display_name: String = ""
@export var icon: Texture2D
@export var max_stack_size: int = 99
@export_multiline var description: String = ""

## Ak je toto nastavené (na id existujúceho Blueprint resource), tento item
## reprezentuje fyzicky nájdenú "schému/recept" - pri zobratí do inventára
## sa rovno odomkne príslušný blueprint a item sa NEULOŽÍ do inventára.
## Blueprint id ostáva String (rastúci katalóg obsahu, nie pevná sada).
@export var grants_blueprint_id: String = ""
