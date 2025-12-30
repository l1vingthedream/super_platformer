extends Node

# Timer system for Super Platformer
# Manages countdown timer with warning state, time-out, and end-of-level bonus

# Constants
const TIMER_INTERVAL = 0.6  # Decrement every 0.6 seconds (game second)
const WARNING_TIME = 100  # Trigger hurry-up at this time
const MUSIC_HURRY_PITCH = 1.5  # Music speed multiplier for hurry-up
const BONUS_TICK_INTERVAL = 0.04  # Time bonus countdown speed (25 ticks/second)
const BONUS_POINTS_PER_TICK = 50  # Points awarded per time unit

# State
var timer_active = false
var warning_triggered = false
var countdown_accumulator = 0.0

# Node references (using $ shorthand since script is attached to Main)
@onready var player = $Player
@onready var flagpole = $Flagpole
@onready var music_player = $AudioStreamPlayer
@onready var hurryup_sound = $HurryUpSound
@onready var coin_sound = $CoinSound

func _ready():
	# Reset time to starting value for this level
	GameManager.time = 400
	timer_active = true
	warning_triggered = false
	countdown_accumulator = 0.0
	print("Timer started at ", GameManager.time)

func _process(delta):
	if not timer_active:
		return

	# Check stop conditions
	if player.is_dead or flagpole.slide_triggered:
		timer_active = false
		print("Timer stopped")
		return

	# Accumulate time
	countdown_accumulator += delta

	# Decrement timer every TIMER_INTERVAL seconds
	if countdown_accumulator >= TIMER_INTERVAL:
		countdown_accumulator -= TIMER_INTERVAL
		GameManager.decrement_time()

		# Check for warning state (exactly once at time == 100)
		if GameManager.time == WARNING_TIME and not warning_triggered:
			trigger_hurry_warning()

		# Check for time-out (time == 0)
		if GameManager.time == 0:
			timer_active = false
			print("TIME UP!")
			player.die()

func trigger_hurry_warning():
	"""Trigger hurry-up warning: play sound and speed up music"""
	warning_triggered = true
	print("HURRY UP! Time remaining: ", WARNING_TIME)

	# Play warning sound
	if hurryup_sound:
		hurryup_sound.play()

	# Speed up background music
	if music_player:
		music_player.pitch_scale = MUSIC_HURRY_PITCH

func start_time_bonus_countdown():
	"""Convert remaining time to points with visual countdown"""
	# Called from flagpole when slide completes
	timer_active = false  # Ensure main timer is stopped

	var remaining_time = GameManager.time
	print("Starting time bonus countdown. Remaining time: ", remaining_time)

	# If no time remaining, skip countdown
	if remaining_time <= 0:
		return

	# Visual countdown loop: decrement time, add points, play sound
	while remaining_time > 0:
		GameManager.decrement_time()  # Updates HUD automatically via signal
		GameManager.add_score(BONUS_POINTS_PER_TICK)

		# Play coin sound for each tick (if not already playing to avoid spam)
		if coin_sound and not coin_sound.playing:
			coin_sound.play()

		remaining_time -= 1
		await get_tree().create_timer(BONUS_TICK_INTERVAL).timeout

	print("Time bonus complete!")

	# Small delay before scene reload
	await get_tree().create_timer(0.5).timeout
