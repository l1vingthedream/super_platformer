extends Node

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
