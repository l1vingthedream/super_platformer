extends Node

# LevelManager - Handles level progression and scene loading for the multi-level system
# Manages 32 levels across 8 worlds (1-1 through 8-4)

# Level registry: maps "world-level" format to scene path
var level_registry: Dictionary = {}

func _ready():
	print("LevelManager initialized")
	_build_level_registry()

func _build_level_registry():
	"""Build the complete registry of all 32 levels"""
	# World 1
	register_level(1, 1, "res://scenes/levels/world_1_1.tscn")
	register_level(1, 2, "res://scenes/levels/world_1_2.tscn")
	register_level(1, 3, "res://scenes/levels/world_1_3.tscn")
	register_level(1, 4, "res://scenes/levels/world_1_4.tscn")

	# World 2
	register_level(2, 1, "res://scenes/levels/world_2_1.tscn")
	register_level(2, 2, "res://scenes/levels/world_2_2.tscn")
	register_level(2, 3, "res://scenes/levels/world_2_3.tscn")
	register_level(2, 4, "res://scenes/levels/world_2_4.tscn")

	# World 3
	register_level(3, 1, "res://scenes/levels/world_3_1.tscn")
	register_level(3, 2, "res://scenes/levels/world_3_2.tscn")
	register_level(3, 3, "res://scenes/levels/world_3_3.tscn")
	register_level(3, 4, "res://scenes/levels/world_3_4.tscn")

	# World 4
	register_level(4, 1, "res://scenes/levels/world_4_1.tscn")
	register_level(4, 2, "res://scenes/levels/world_4_2.tscn")
	register_level(4, 3, "res://scenes/levels/world_4_3.tscn")
	register_level(4, 4, "res://scenes/levels/world_4_4.tscn")

	# World 5
	register_level(5, 1, "res://scenes/levels/world_5_1.tscn")
	register_level(5, 2, "res://scenes/levels/world_5_2.tscn")
	register_level(5, 3, "res://scenes/levels/world_5_3.tscn")
	register_level(5, 4, "res://scenes/levels/world_5_4.tscn")

	# World 6
	register_level(6, 1, "res://scenes/levels/world_6_1.tscn")
	register_level(6, 2, "res://scenes/levels/world_6_2.tscn")
	register_level(6, 3, "res://scenes/levels/world_6_3.tscn")
	register_level(6, 4, "res://scenes/levels/world_6_4.tscn")

	# World 7
	register_level(7, 1, "res://scenes/levels/world_7_1.tscn")
	register_level(7, 2, "res://scenes/levels/world_7_2.tscn")
	register_level(7, 3, "res://scenes/levels/world_7_3.tscn")
	register_level(7, 4, "res://scenes/levels/world_7_4.tscn")

	# World 8
	register_level(8, 1, "res://scenes/levels/world_8_1.tscn")
	register_level(8, 2, "res://scenes/levels/world_8_2.tscn")
	register_level(8, 3, "res://scenes/levels/world_8_3.tscn")
	register_level(8, 4, "res://scenes/levels/world_8_4.tscn")

	print("Level registry built with ", level_registry.size(), " levels")

func register_level(world: int, level: int, path: String):
	"""Register a level scene path in the registry"""
	var key = "%d-%d" % [world, level]
	level_registry[key] = path

func get_level_path(world: int, level: int) -> String:
	"""Get the scene path for a given world and level"""
	var key = "%d-%d" % [world, level]
	return level_registry.get(key, "")

func load_current_level():
	"""Load the level based on GameManager's current world and level"""
	var level_path = get_level_path(GameManager.world, GameManager.level)

	if level_path.is_empty():
		push_error("No level found for world %d-%d" % [GameManager.world, GameManager.level])
		return

	print("Loading level %d-%d: %s" % [GameManager.world, GameManager.level, level_path])
	get_tree().change_scene_to_file(level_path)

func advance_to_next_level():
	"""Progress to the next level in sequence (1-1 → 1-2 → ... → 8-4)"""
	print("Advancing from level %d-%d" % [GameManager.world, GameManager.level])

	# Check if we just completed the final level (8-4)
	if GameManager.world == 8 and GameManager.level == 4:
		show_victory_screen()
		return

	# Advance to next level
	if GameManager.level < 4:
		# Move to next level in current world
		GameManager.level += 1
	elif GameManager.world < 8:
		# Move to first level of next world
		GameManager.world += 1
		GameManager.level = 1

	print("Advanced to level %d-%d" % [GameManager.world, GameManager.level])

	# Reset time for new level
	GameManager.time = 400

	# Load the next level
	load_current_level()

func restart_current_level():
	"""Reload the current level (called after player death with lives remaining)"""
	print("Restarting level %d-%d" % [GameManager.world, GameManager.level])

	# Reset time for retry
	GameManager.time = 400

	# Reload same level
	load_current_level()

func reset_to_start():
	"""Reset to world 1-1 (called on game over or new game)"""
	print("Resetting to world 1-1")
	GameManager.world = 1
	GameManager.level = 1
	GameManager.time = 400

func show_victory_screen():
	"""Display victory message after completing world 8-4"""
	print("CONGRATULATIONS! You beat the game!")
	print("Final Score: %d" % GameManager.score)

	# Wait 3 seconds to show victory message
	await get_tree().create_timer(3.0).timeout

	# Return to title screen
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")
