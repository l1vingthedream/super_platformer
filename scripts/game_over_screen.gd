extends Node2D

const DISPLAY_DURATION = 3.0  # Show for 3 seconds

@onready var game_over_sound = $GameOverSound

func _ready():
	# Play game over sound
	game_over_sound.play()

	# Disable input during display
	set_process_input(false)

	# Reset game state
	GameManager.reset_game()

	# Wait for display duration
	await get_tree().create_timer(DISPLAY_DURATION).timeout

	# Return to main scene (or title screen when implemented)
	get_tree().change_scene_to_file("res://scenes/main.tscn")
