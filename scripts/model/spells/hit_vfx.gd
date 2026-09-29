extends Node2D

@export var lifetime: float = 0.4

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	z_index = 20  # nad terénom aj entitami
	sprite.play("default")

	# Ak máš animáciu s vypnutým Loop, elegantnejšie je počkať na jej koniec:
	# sprite.animation_finished.connect(queue_free)
	await get_tree().create_timer(lifetime).timeout
	queue_free()
