extends Node

# Player name
const PLAYER_NAME = "ROCCO"

# Lives system
const STARTING_LIVES = 3
var current_lives: int = STARTING_LIVES

# Game state
var coins: int = 0
var score: int = 0
var top_score: int = 0  # Persistent high score
var save_file_path: String = "user://top_score.dat"  # Save file path
var time: int = 400  # Starting time in seconds
var world: int = 1
var level: int = 1

# Signals
signal player_died(lives_remaining: int)
signal game_over
signal life_lost
signal coin_collected(new_total: int)
signal score_changed(new_score: int)
signal time_changed(new_time: int)

func _ready():
	print("GameManager initialized with ", STARTING_LIVES, " lives")
	load_top_score()

func reset_game():
	"""Reset all game state to starting values"""
	current_lives = STARTING_LIVES
	coins = 0
	score = 0
	time = 400
	world = 1
	level = 1
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

func collect_coin():
	"""Add a coin and emit signal"""
	coins += 1
	emit_signal("coin_collected", coins)
	add_score(200)  # Each coin is worth 200 points

	# Grant 1UP every 100 coins
	if coins >= 100 and coins % 100 == 0:
		add_life()

func add_score(points: int):
	"""Add points to score and emit signal"""
	score += points
	emit_signal("score_changed", score)

func update_top_score():
	"""Check if current score is a new top score and save if so"""
	if score > top_score:
		top_score = score
		save_top_score()
		print("New top score: ", top_score)

func save_top_score():
	"""Save top score to persistent storage"""
	var file = FileAccess.open(save_file_path, FileAccess.WRITE)
	if file:
		file.store_32(top_score)
		file.close()
		print("Top score saved: ", top_score)
	else:
		print("ERROR: Could not save top score")

func load_top_score():
	"""Load top score from persistent storage"""
	if FileAccess.file_exists(save_file_path):
		var file = FileAccess.open(save_file_path, FileAccess.READ)
		if file:
			top_score = file.get_32()
			file.close()
			print("Top score loaded: ", top_score)
		else:
			print("ERROR: Could not load top score")
	else:
		print("No saved top score found, starting at 0")
		top_score = 0

func decrement_time():
	"""Decrease time by 1 and emit signal"""
	if time > 0:
		time -= 1
		emit_signal("time_changed", time)

		if time == 0:
			# Time up causes death
			emit_signal("game_over")

func get_letter_region(letter: String) -> Rect2:
	"""Get the sprite region for a single letter/number/character from the HUD sprite sheet"""
	# HUDs_Screens.png layout at y=105:
	# Positions 0-9: Digits 0-9 (x = digit * 9)
	# Position 10: Special character "-"
	# Positions 11+: Letters A-Z (x = (letter_index + 10) * 9)
	# Examples from existing code: C at 108, O at 216, R at 243

	var char = letter.to_upper()
	var char_code = char.unicode_at(0)

	# Handle digits 0-9
	if char_code >= 48 and char_code <= 57:  # 0-9
		var digit = char_code - 48
		return Rect2(digit * 9, 105, 8, 8)

	# Handle letters A-Z
	elif char_code >= 65 and char_code <= 90:  # A-Z
		var letter_index = char_code - 65  # A=0, B=1, etc.
		var x = (letter_index + 10) * 9
		return Rect2(x, 105, 8, 8)

	# Handle special characters
	elif char == "-":
		return Rect2(108, 114, 8, 8)  # Dash/hyphen character
	elif char == " ":
		return Rect2(0, 0, 8, 8)  # Blank/transparent
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

func spawn_floating_score(points: int, world_position: Vector2):
	"""Spawn a floating score label at the given world position"""
	# Load the floating score scene
	var floating_score_scene = load("res://scenes/floating_score.tscn")
	var floating_score = floating_score_scene.instantiate()

	# Set the position and score value
	floating_score.global_position = world_position
	floating_score.set_score(points)

	# Add to the current scene (get the main scene tree root)
	get_tree().current_scene.add_child(floating_score)
