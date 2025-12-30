extends Node2D

const DISPLAY_DURATION = 2.0  # Show for 2 seconds

@onready var life_count_sprite = $LifeCountSprite
@onready var hud_texture = preload("res://assets/sprites/HUDs_Screens.png")

func _ready():
	# Create player name display
	GameManager.create_text_sprites(self, GameManager.PLAYER_NAME, Vector2(331, 51), Vector2(3, 3), hud_texture)

	# Display current lives count
	update_life_display()

	# Wait 2 seconds then return to main scene
	await get_tree().create_timer(DISPLAY_DURATION).timeout
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func update_life_display():
	"""Update the number sprite to show current lives"""
	var lives = GameManager.get_lives()

	# Update sprite region based on lives count (0-9)
	if life_count_sprite:
		var digit = clampi(lives, 0, 9)
		var region_x = digit * 9  # 8px + 1px separation
		life_count_sprite.region_rect = Rect2(region_x, 105, 8, 8)
