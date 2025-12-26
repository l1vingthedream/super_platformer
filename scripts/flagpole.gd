extends Node2D

# Slide parameters
const SLIDE_SPEED = 120.0  # pixels per second

# State
var slide_triggered = false

# References
@onready var player_detector = $PlayerDetector
@onready var flagpole_sound = $FlagpoleSound

func _ready():
	print("DEBUG: Flagpole initialized at position: ", global_position)

func _on_player_detected(body):
	if slide_triggered or body.name != "Player":
		return

	print("DEBUG: Player touched flagpole!")
	slide_triggered = true
	start_slide_sequence(body)

func start_slide_sequence(player: CharacterBody2D):
	# Stop background music
	var music_player = get_tree().get_first_node_in_group("music")
	if not music_player:
		music_player = get_parent().get_node_or_null("AudioStreamPlayer")
	if music_player:
		music_player.stop()

	# Play flagpole sound
	flagpole_sound.play()

	# Calculate slide parameters (half speed = double duration)
	var player_start_y = player.global_position.y
	var slide_target_y = global_position.y  # Ground level
	var slide_distance = slide_target_y - player_start_y
	var actual_duration = max(1.0, abs(slide_distance) / SLIDE_SPEED * 2.0)

	print("DEBUG: Slide from y=", player_start_y, " to y=", slide_target_y)

	# Lock player state
	player.is_sliding = true
	player.velocity = Vector2.ZERO

	# Play slide animation (uses get_animation_name for power state)
	var anim_name = player.get_animation_name("slide")
	player.get_node("AnimatedSprite2D").play(anim_name)

	# Disable player collision
	player.get_node("CollisionShape2D").disabled = true

	# Get player collision shape to calculate sprite bottom
	var collision_shape = player.get_node("CollisionShape2D")
	var shape_height = collision_shape.shape.size.y

	# Calculate flag start and end positions (32px below player sprite bottom)
	var player_bottom_offset = shape_height / 2.0
	var flag_start_y = player_start_y + player_bottom_offset + 32
	var flag_end_y = slide_target_y + player_bottom_offset + 32

	# Create slide tween
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)

	# Slide down the pole (only move Y, keep X position)
	tween.tween_property(
		player,
		"global_position:y",
		slide_target_y,
		actual_duration
	)

	# Move flag down in parallel (16px below player bottom)
	tween.parallel().tween_property(
		$FlagSprite,
		"global_position:y",
		flag_end_y,
		actual_duration
	)

	# When slide completes
	tween.tween_callback(on_slide_complete)

func on_slide_complete():
	print("DEBUG: Slide complete!")
	await get_tree().create_timer(0.5).timeout
	get_tree().reload_current_scene()
