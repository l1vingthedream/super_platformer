extends Node2D

const DISPLAY_DURATION = 3.0  # Show for 3 seconds

@onready var game_over_sound = $GameOverSound
@onready var hud_texture = preload("res://assets/sprites/HUDs_Screens.png")

func _ready():
	# Create player name display
	GameManager.create_text_sprites(self, GameManager.PLAYER_NAME, Vector2(331, 51), Vector2(3, 3), hud_texture)

	# Play game over sound
	game_over_sound.play()

	# Disable input during display
	set_process_input(false)

	# Reset game state
	GameManager.reset_game()

	# Wait for display duration
	await get_tree().create_timer(DISPLAY_DURATION).timeout

	# Return to title screen
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")
