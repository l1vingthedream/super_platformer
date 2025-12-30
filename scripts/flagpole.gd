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

	# Calculate slide parameters
	var player_start_y = player.global_position.y
	var slide_target_y = -88.0  # Stop 40 pixels above ground tile at y=-48
	var slide_distance = abs(slide_target_y - player_start_y)
	var actual_duration = max(1.0, slide_distance / SLIDE_SPEED)

	# Award height-based points (top of pole = 5000, bottom = 100)
	# Flagpole height spans from approximately y=-200 (top) to y=-88 (bottom)
	var flagpole_top_y = -200.0
	var flagpole_bottom_y = slide_target_y  # -88.0
	var height_ratio = clamp((flagpole_bottom_y - player_start_y) / (flagpole_bottom_y - flagpole_top_y), 0.0, 1.0)
	var points = int(lerp(5000.0, 100.0, 1.0 - height_ratio))

	# Round to nearest valid score value (100, 400, 500, 1000, 2000, 4000, 5000)
	if points >= 4500:
		points = 5000
	elif points >= 3000:
		points = 4000
	elif points >= 1500:
		points = 2000
	elif points >= 750:
		points = 1000
	elif points >= 450:
		points = 500
	elif points >= 250:
		points = 400
	else:
		points = 100

	GameManager.add_score(points)
	GameManager.spawn_floating_score(points, player.global_position)
	print("DEBUG: Flagpole height bonus: ", points, " points")

	print("DEBUG: Slide from y=", player_start_y, " to y=", slide_target_y)

	# Lock player state
	player.is_sliding = true
	player.velocity = Vector2.ZERO

	# Play slide animation (uses get_animation_name for power state)
	var anim_name = player.get_animation_name("slide")
	player.get_node("AnimatedSprite2D").play(anim_name)

	# Disable player collision
	player.get_node("CollisionShape2D").disabled = true

	# Calculate flag positions - flag stops at y=-70
	var flag_end_y = -70.0
	var flag_distance = abs(flag_end_y - $FlagSprite.global_position.y)
	var flag_duration = flag_distance / SLIDE_SPEED

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

	# Move flag down in parallel, but stop at y=-70
	tween.parallel().tween_property(
		$FlagSprite,
		"global_position:y",
		flag_end_y,
		flag_duration
	)

	# When slide completes, do the landing sequence
	tween.tween_callback(func(): landing_sequence(player))

func landing_sequence(player: CharacterBody2D):
	print("DEBUG: Landing sequence started")

	# Set player z-index to render in front of castle
	player.z_index = 10

	# Step 1: Move to right side of flagpole at x=3191, facing left
	player.get_node("AnimatedSprite2D").flip_h = true  # Face left

	var move_tween = create_tween()
	move_tween.tween_property(
		player,
		"global_position:x",
		3191.0,
		0.3
	)

	await move_tween.finished

	# Step 2: Jump off flagpole
	player.get_node("AnimatedSprite2D").play(player.get_animation_name("jump"))

	var jump_tween = create_tween()
	jump_tween.set_parallel(true)

	# Jump arc: up then down
	jump_tween.tween_property(
		player,
		"global_position:y",
		-120.0,  # Jump up 32 pixels
		0.3
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	jump_tween.chain().tween_property(
		player,
		"global_position:y",
		-48.0,  # Land on ground
		0.3
	).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)

	# Move right while jumping
	jump_tween.parallel().tween_property(
		player,
		"global_position:x",
		3230.0,  # Move right during jump
		0.6
	)

	await jump_tween.finished

	# Step 3: Walk to castle doorway at x=3294
	player.get_node("AnimatedSprite2D").flip_h = false  # Face right toward castle
	player.get_node("AnimatedSprite2D").play(player.get_animation_name("walk"))

	var walk_tween = create_tween()
	walk_tween.tween_property(
		player,
		"global_position:x",
		3294.0,
		0.8
	)

	await walk_tween.finished

	# Complete level
	on_slide_complete()

func on_slide_complete():
	print("DEBUG: Level complete!")
	await get_tree().create_timer(1.0).timeout
	get_tree().reload_current_scene()
