extends Node

# Player name
const PLAYER_NAME = "ROCCO"

# Lives system
const STARTING_LIVES = 3
var current_lives: int = STARTING_LIVES

# Future: Score and coins (implement later)
var coins: int = 0
var score: int = 0

# Signals
signal player_died(lives_remaining: int)
signal game_over
signal life_lost

func _ready():
	print("GameManager initialized with ", STARTING_LIVES, " lives")

func reset_game():
	"""Reset all game state to starting values"""
	current_lives = STARTING_LIVES
	coins = 0
	score = 0
	print("Game state reset")

func decrement_life() -> int:
	"""Remove one life and return remaining lives"""
	current_lives -= 1
	print("Life lost! Lives remaining: ", current_lives)
	emit_signal("player_died", current_lives)

	if current_lives <= 0:
		emit_signal("game_over")
		print("GAME OVER!")

	return current_lives

func get_lives() -> int:
	"""Get current number of lives"""
	return current_lives

func add_life():
	"""Grant an extra life (for 100 coins, 1UP mushroom, etc.)"""
	current_lives += 1
	print("Extra life! Lives: ", current_lives)

func get_letter_region(letter: String) -> Rect2:
	"""Get the sprite region for a single letter from the HUD sprite sheet"""
	# Letters are in HUDs_Screens.png at y=105
	# They start after digits 0-9 (positions 0-9) and special char at position 10
	# Formula: x = (letter_index + 10) * 9, where A=0, B=1, etc.
	# Examples: C at 108, O at 216, R at 243

	var upper_letter = letter.to_upper()
	var letter_code = upper_letter.unicode_at(0)

	if letter_code >= 65 and letter_code <= 90:  # A-Z
		var letter_index = letter_code - 65  # A=0, B=1, etc.
		var x = (letter_index + 10) * 9
		return Rect2(x, 105, 8, 8)
	else:
		# Return space/blank for unknown characters
		return Rect2(0, 0, 8, 8)

func create_text_sprites(parent: Node, text: String, start_pos: Vector2, sprite_scale: Vector2, texture: Texture2D):
	"""Create letter sprites as children of parent node to display text"""
	var letter_spacing = 27  # 9 pixels * 3 scale = 27 pixels between letters

	for i in range(text.length()):
		var letter = text[i]
		var sprite = Sprite2D.new()
		sprite.name = "Letter" + str(i)
		sprite.texture = texture
		sprite.region_enabled = true
		sprite.region_rect = get_letter_region(letter)
		sprite.scale = sprite_scale
		sprite.position = start_pos + Vector2(i * letter_spacing, 0)
		parent.add_child(sprite)
