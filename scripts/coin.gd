extends Area2D

# Collectible coin that can be placed in levels
# Player walks through it to collect

@onready var coin_sound = $CoinSound
@onready var sprite = $AnimatedSprite2D

func _ready():
	# Connect to detect when player touches coin
	body_entered.connect(_on_body_entered)

	# Start coin animation
	sprite.play("coin")

func _on_body_entered(body: Node2D):
	# Only collect if player touches it
	if body.name == "Player":
		collect()

func collect():
	# Play collection sound
	coin_sound.play()

	# Update game state (increments coin count, awards points, checks 100-coin bonus)
	GameManager.collect_coin()

	# Hide sprite immediately for instant visual feedback
	sprite.visible = false

	# Disable collision so we don't collect twice
	set_deferred("monitoring", false)

	# Wait for sound to finish, then remove coin
	await coin_sound.finished
	queue_free()
