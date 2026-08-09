extends CharacterBody2D

@export var speed: float = 300.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	# Fix na chýbajúcu idle animáciu pri štarte - play() sa musí zavolať
	# manuálne aspoň raz, inak sprite len zobrazuje posledný editovaný frame.
	animated_sprite.play("idle")


func _physics_process(_delta: float) -> void:
	# Input.get_vector potrebuje, aby si mal v Project Settings -> Input Map
	# vytvorené akcie: move_left (A), move_right (D), move_up (W), move_down (S)
	# TODO: pohyb na zaklade delty?
	var input_vector: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		
	velocity = input_vector * speed * 2 if Input.is_action_pressed("sprint") else input_vector * speed
	move_and_slide()

	_update_animation(input_vector)


func _update_animation(input_vector: Vector2) -> void:
	var moving: bool = input_vector.length() > 0.1
	var anim_name: String

	if moving:
		anim_name = "walk"
	else:
		anim_name = "idle"

	# play() volaj len keď sa animácia skutočne mení, inak sa reštartuje
	# každý frame od prvej snímky a vyzerá to "trhavo".
	if animated_sprite.animation != anim_name:
		animated_sprite.play(anim_name)

	# Keďže zatiaľ nemáš samostatné animácie pre každý z 8 smerov, aspoň
	# prevrátenie sprite-u podľa horizontálneho smeru dá hráčovi vizuálnu
	# spätnú väzbu, že sa pozerá doľava/doprava.
	if input_vector.x != 0:
		animated_sprite.flip_h = input_vector.x < 0

# --------------------------------------------------------------------------
# Keď neskôr pridáš samostatné animácie pre všetkých 8 smerov (idle_0..idle_7,
# walk_0..walk_7), napíš mi a vrátime sa k smerovej verzii skriptu, ktorú
# prepína animáciu podľa uhla pohybu namiesto len flip_h.
# --------------------------------------------------------------------------
