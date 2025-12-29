extends Node2D

@onready var animated_sprite = $AnimatedSprite2D

func _ready():
	# Play explosion animation
	animated_sprite.play("explode")

	# Remove after animation completes
	await animated_sprite.animation_finished
	queue_free()
