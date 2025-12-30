extends CharacterBody2D

# Power-up state system
enum PowerUpState { SMALL, BIG, FIRE, INVINCIBLE }
var current_power_state: PowerUpState = PowerUpState.SMALL
var is_growing = false
var is_shrinking = false

# Fire transformation animation
var is_transforming_to_fire = false
const FIRE_TRANSFORM_DURATION = 1.0  # 60 frames at 60 FPS
const PALETTE_SWAP_INTERVAL = 0.05   # Swap every 3 frames (2-4 frames range)

# Fireball tracking
var active_fireballs = []
const MAX_FIREBALLS = 2
var is_throwing = false
var throw_animation_timer = 0.0
const THROW_ANIMATION_DURATION = 0.167  # ~10 frames at 60 FPS

# Movement constants - Momentum-based system
# Classic SMB values: Walk = 1.5px/frame, Run = 2.5px/frame @ 60fps
const WALK_MAX_SPEED = 120.0        # Maximum walking speed (1.5 * 60fps)
const RUN_MAX_SPEED = 200.0        # Maximum running speed (2.5 * 60fps) - 66.7% faster
const GROUND_ACCELERATION = 2400.0  # Acceleration on ground
const AIR_ACCELERATION = 600.0     # Reduced acceleration in air
const GROUND_FRICTION = 2500.0     # Deceleration when no input
const SKID_FRICTION = 920.0        # Friction when skidding (10-16 frames to stop from full sprint)

const JUMP_VELOCITY = -350.0
const JUMP_HOLD_THRESHOLD = 0.1  # Time in seconds to distinguish short vs long jump
const SKID_THRESHOLD = 10.0      # Velocity threshold for skid animation (show skid until nearly stopped)

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_skidding = false  # Track if player is skidding

# Death system
var is_dead = false

# Flagpole sliding system
var is_sliding = false

# Damage system
var is_invulnerable = false
const INVULNERABILITY_DURATION = 2.0  # Seconds of invincibility after taking damage
const ENEMY_BOUNCE_VELOCITY = -250.0  # Upward bounce when stomping enemy

# Combo scoring system
var enemy_stomp_count = 0  # Consecutive stomps without touching ground
const STOMP_COMBO_POINTS = [100, 200, 400, 800, 1000, 2000, 4000, 8000]  # Points per combo level

# Jump system
var jump_hold_time = 0.0
var is_jumping = false

@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D
@onready var death_sound = $DeathSound
@onready var jump_sound = $JumpSound
@onready var jump_small_sound = $JumpSmallSound
@onready var powerup_sound = $PowerUpSound
@onready var big_jump_sound = $BigJumpSound
@onready var shrink_sound = $ShrinkSound
@onready var fireball_sound = $FireballSound
@onready var one_up_sound = $OneUpSound

func _ready():
	# Make player discoverable by items
	add_to_group("player")

	# Set z_index so player renders in front of enemies during collisions
	z_index = 1

	print("DEBUG: Player initialized in power state: ", current_power_state)

	# Ensure collision box is correct size for current state
	resize_collision_box(current_power_state)

func power_up(new_state: PowerUpState):
	# Ignore if already at or above this state
	if current_power_state >= new_state:
		print("DEBUG: Already at state ", current_power_state, ", ignoring power-up")
		return

	# Play sound
	powerup_sound.play()

	# Award points for collecting power-up
	GameManager.add_score(1000)

	# Trigger transition
	if new_state == PowerUpState.FIRE and current_power_state == PowerUpState.BIG:
		# BIG → FIRE: palette swap transformation
		play_fire_transformation()
	elif new_state == PowerUpState.BIG and current_power_state == PowerUpState.SMALL:
		# SMALL → BIG: existing growth animation
		set_power_state(new_state)
	else:
		# Direct state change
		set_power_state(new_state)

func set_power_state(new_state: PowerUpState):
	var old_state = current_power_state
	current_power_state = new_state
	print("DEBUG: Power state changed from ", old_state, " to ", new_state)

	if new_state == PowerUpState.BIG and old_state == PowerUpState.SMALL:
		play_growth_animation()

func play_growth_animation():
	is_growing = true
	print("DEBUG: Starting growth animation")
	animated_sprite.play("grow")
	await animated_sprite.animation_finished
	print("DEBUG: Growth animation finished")
	is_growing = false
	resize_collision_box(PowerUpState.BIG)

func play_fire_transformation():
	"""Palette swap animation for BIG → FIRE transformation"""
	is_transforming_to_fire = true

	# Freeze game
	get_tree().paused = true
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Color palette sequences (modulate colors)
	# Big Mario: #B53120 (red), #ea9e22 (orange), #6b6d00 (dark yellow)
	var palette_1 = Color("#B53120")  # Standard (no change)
	var palette_2 = Color("#0C9300")  # Green swap
	var palette_3 = Color("#000000")  # Black swap
	var palette_4 = Color("#ffffff")  # Fire Mario final (white/red)

	var palettes = [palette_1, palette_2, palette_3, palette_4, palette_1, palette_2, palette_3, palette_4]
	var swap_count = 0
	var total_swaps = 20  # 20 swaps * 0.05s = 1 second

	# Palette swap loop
	while swap_count < total_swaps:
		var palette_index = swap_count % palettes.size()
		animated_sprite.modulate = palettes[palette_index]
		await get_tree().create_timer(PALETTE_SWAP_INTERVAL).timeout
		swap_count += 1

	# Final form: switch to Fire Mario sprites
	animated_sprite.modulate = Color(1, 1, 1, 1)  # Reset modulate
	set_power_state(PowerUpState.FIRE)

	# Unfreeze game
	get_tree().paused = false
	process_mode = Node.PROCESS_MODE_INHERIT
	is_transforming_to_fire = false

	print("DEBUG: Fire transformation complete")

func play_shrink_animation():
	is_shrinking = true
	print("DEBUG: Starting shrink animation")

	# Play shrink sound
	shrink_sound.play()

	# Store original Y position before animation
	var original_y = global_position.y

	# Play shrink animation
	animated_sprite.play("shrink")
	await animated_sprite.animation_finished

	print("DEBUG: Shrink animation finished")

	# Adjust Y position to keep feet on ground
	# Big hitbox is 16x32 centered (bottom at Y+16)
	# Small hitbox is 16x16 centered (bottom at Y+8)
	# Need to move down by 8 pixels
	global_position.y = original_y + 8.0

	# Resize collision box to small
	resize_collision_box(PowerUpState.SMALL)

	is_shrinking = false
	print("DEBUG: Player shrunk to small size")

func resize_collision_box(state: PowerUpState):
	match state:
		PowerUpState.SMALL:
			collision_shape.shape.size = Vector2(14, 16)
			print("DEBUG: Collision box resized to SMALL (14x16)")
		PowerUpState.BIG:
			collision_shape.shape.size = Vector2(16, 32)
			print("DEBUG: Collision box resized to BIG (16x32)")

func get_animation_name(base_name: String) -> String:
	# Special case: throwing animation for Fire Mario
	if is_throwing and current_power_state == PowerUpState.FIRE:
		return "fire_throw"

	# State-based animation prefixes
	match current_power_state:
		PowerUpState.FIRE:
			return "fire_" + base_name
		PowerUpState.BIG:
			return "big_" + base_name
		_:
			return base_name

func _physics_process(delta):
	# Check for death (top of sprite below y=0)
	if not is_dead and global_position.y > 8:
		die()
		return

	if not is_on_floor():
		velocity.y += gravity * delta

		# Variable jump height: if jump button released while moving up, cut jump short
		if is_jumping and not Input.is_action_pressed("jump") and velocity.y < 0:
			velocity.y *= 0.5
			is_jumping = false

	# Control locking during growth animation
	if is_growing:
		# Maintain momentum but no new input
		velocity.x = move_toward(velocity.x, 0, GROUND_FRICTION * 0.5 * delta)
		move_and_slide()
		return  # Skip normal control logic

	# Control locking during shrink animation
	if is_shrinking:
		# Maintain momentum but no new input
		velocity.x = move_toward(velocity.x, 0, GROUND_FRICTION * 0.5 * delta)
		move_and_slide()
		return  # Skip normal control logic

	# Control locking during flagpole slide
	if is_sliding:
		# No player control during slide - flagpole tween controls position
		return

	# Control locking during death sequence
	if is_dead:
		# No control during death - death animation handles everything
		return

	# Track jump hold time
	if is_jumping and Input.is_action_pressed("jump"):
		jump_hold_time += delta

		# Upgrade to long jump sound if button held past threshold
		if jump_hold_time >= JUMP_HOLD_THRESHOLD and jump_small_sound.playing:
			jump_small_sound.stop()
			jump_sound.play()

	# Jump initiation
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		is_jumping = true
		jump_hold_time = 0.0

		# Big/Fire Mario: always play big jump sound immediately
		if current_power_state >= PowerUpState.BIG:
			big_jump_sound.play()
		else:
			# Small Mario: start with small jump sound (assume quick tap)
			jump_small_sound.play()

	# Reset jump state when landing
	if is_on_floor():
		is_jumping = false
		jump_hold_time = 0.0
		# Reset combo counter when touching ground
		enemy_stomp_count = 0

	# Handle throw animation timer
	if is_throwing:
		throw_animation_timer -= delta
		if throw_animation_timer <= 0:
			is_throwing = false

	# Fireball shooting (only when Fire state)
	# Contextual: X button shoots when standing/jumping, runs when moving
	if current_power_state == PowerUpState.FIRE and not is_transforming_to_fire:
		if Input.is_action_just_pressed("run"):
			# Only shoot if not running (velocity near zero) OR in the air
			if abs(velocity.x) < 50.0 or not is_on_floor():
				if active_fireballs.size() < MAX_FIREBALLS:
					shoot_fireball()

	# Get input
	var direction = Input.get_axis("move_left", "move_right")
	var is_running = Input.is_action_pressed("run")

	# Determine max speed based on run button
	var max_speed = RUN_MAX_SPEED if is_running else WALK_MAX_SPEED

	# Determine acceleration based on ground state
	var acceleration = GROUND_ACCELERATION if is_on_floor() else AIR_ACCELERATION

	# Handle horizontal movement with momentum
	if direction != 0:
		# Check if trying to turn while moving fast (skidding)
		var is_trying_to_turn = (velocity.x > SKID_THRESHOLD and direction < 0) or (velocity.x < -SKID_THRESHOLD and direction > 0)

		if is_trying_to_turn and is_on_floor():
			# Skidding - stronger friction to slow down before turning
			is_skidding = true
			velocity.x = move_toward(velocity.x, 0, SKID_FRICTION * delta)
		else:
			# Normal acceleration toward target speed
			is_skidding = false
			var target_velocity = direction * max_speed
			velocity.x = move_toward(velocity.x, target_velocity, acceleration * delta)
	else:
		# No input - apply friction
		is_skidding = false
		var friction = GROUND_FRICTION if is_on_floor() else GROUND_FRICTION * 0.5  # Less friction in air
		velocity.x = move_toward(velocity.x, 0, friction * delta)

	move_and_slide()

	# Animation logic - velocity-based skid detection
	# Show skid sprite when:
	# 1. On floor
	# 2. Input direction is opposite to velocity direction
	# 3. Input direction is not zero (actively pressing opposite direction)
	# 4. Velocity magnitude is above threshold (moving fast enough)
	var should_show_skid = (
		is_on_floor() and
		direction != 0 and
		sign(direction) != sign(velocity.x) and
		abs(velocity.x) > SKID_THRESHOLD
	)

	# Determine sprite facing direction
	# During skid: face the direction of momentum (velocity)
	# Otherwise: face the direction of input (or keep current if no input)
	var sprite_should_flip_left = false
	if should_show_skid:
		# Face the direction of momentum during skid
		sprite_should_flip_left = velocity.x < 0
	elif direction != 0:
		# Face the direction of input when not skidding
		sprite_should_flip_left = direction < 0
	else:
		# No input - keep current facing
		sprite_should_flip_left = animated_sprite.flip_h

	# Apply animations
	if not is_on_floor():
		animated_sprite.play(get_animation_name("jump"))
	elif should_show_skid:
		animated_sprite.play(get_animation_name("turn"))
	elif direction != 0:
		animated_sprite.play(get_animation_name("walk"))
	else:
		animated_sprite.play(get_animation_name("idle"))

	# Apply sprite flip
	animated_sprite.flip_h = sprite_should_flip_left

func die():
	is_dead = true
	print("DEBUG: Player death sequence started")

	# Hit stop - freeze game for 0.5 seconds
	# Allow player to continue processing for death animation
	var original_mode = process_mode
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	await get_tree().create_timer(0.5, true, false, true).timeout  # Process always timer
	get_tree().paused = false
	process_mode = original_mode

	# Change to death sprite
	animated_sprite.play("death")

	# Stop horizontal movement, apply upward pop
	velocity.x = 0
	velocity.y = -300.0  # Small upward hop

	# Disable collision (fall through floors)
	collision_layer = 0
	collision_mask = 0

	# Stop background music
	var music_player = get_tree().get_first_node_in_group("music")
	if not music_player:
		music_player = get_parent().get_node_or_null("AudioStreamPlayer")
	if music_player:
		music_player.pitch_scale = 1.0  # Reset pitch before stopping
		music_player.stop()

	# Play death sound and wait for it to finish (2.7 seconds)
	death_sound.play()

	# Apply gravity and fall while death sound plays
	while death_sound.playing:
		velocity.y += gravity * get_physics_process_delta_time()
		global_position.y += velocity.y * get_physics_process_delta_time()
		await get_tree().process_frame

	print("DEBUG: Death sound finished")

	# Decrement life and check if player has lives remaining
	var lives_remaining = GameManager.decrement_life()

	if lives_remaining > 0:
		# Still have lives - show life screen then reload level
		print("DEBUG: Lives remaining, showing life screen")
		get_tree().change_scene_to_file("res://scenes/life_screen.tscn")
	else:
		# No lives left - game over
		print("DEBUG: No lives remaining, game over")
		get_tree().change_scene_to_file("res://scenes/game_over_screen.tscn")

func bounce_off_enemy() -> int:
	"""Apply upward bounce when player stomps on enemy and award combo points"""
	velocity.y = ENEMY_BOUNCE_VELOCITY

	# Award points based on combo count
	var points = 0
	if enemy_stomp_count < STOMP_COMBO_POINTS.size():
		points = STOMP_COMBO_POINTS[enemy_stomp_count]
		GameManager.add_score(points)
	else:
		# Beyond 8 stomps, grant 1UP each time
		GameManager.add_life()
		one_up_sound.play()  # Play 1UP sound for combo reward
		points = -1  # Special value to indicate 1UP

	# Increment combo counter
	enemy_stomp_count += 1

	print("DEBUG: Player bounced off enemy, combo: ", enemy_stomp_count, " points: ", points)
	return points

func take_damage():
	"""Handle player taking damage from enemy"""
	# Ignore damage if already invulnerable, dead, or shrinking
	if is_invulnerable or is_dead or is_shrinking:
		return

	print("DEBUG: Player taking damage! Current state: ", current_power_state)

	# If powered up (BIG, FIRE, or INVINCIBLE), shrink to SMALL
	if current_power_state > PowerUpState.SMALL:
		# Freeze game for ~1 second during shrink animation
		# Use process_mode to allow player animation to continue
		var original_mode = process_mode
		process_mode = Node.PROCESS_MODE_ALWAYS
		get_tree().paused = true

		# Change power state
		set_power_state(PowerUpState.SMALL)

		# Play shrink animation (this will resize hitbox when done)
		await play_shrink_animation()

		# Unfreeze game
		get_tree().paused = false
		process_mode = original_mode

		# Grant invulnerability frames
		is_invulnerable = true
		start_invulnerability_animation()

		# End invulnerability after duration
		await get_tree().create_timer(INVULNERABILITY_DURATION).timeout
		is_invulnerable = false
		animated_sprite.modulate = Color(1, 1, 1, 1)  # Reset to full opacity
		print("DEBUG: Invulnerability ended")
	else:
		# Small Mario dies
		die()

func start_invulnerability_animation():
	"""Flashing effect during invulnerability"""
	var flash_count = 0
	var max_flashes = int(INVULNERABILITY_DURATION * 8)  # Flash 8 times per second

	while flash_count < max_flashes and is_invulnerable:
		animated_sprite.modulate = Color(1, 1, 1, 0.3)  # Transparent
		await get_tree().create_timer(0.0625).timeout
		if not is_invulnerable:
			break
		animated_sprite.modulate = Color(1, 1, 1, 1)  # Opaque
		await get_tree().create_timer(0.0625).timeout
		flash_count += 1

func shoot_fireball():
	"""Spawn a fireball projectile"""
	# Play throw animation
	is_throwing = true
	throw_animation_timer = THROW_ANIMATION_DURATION

	# Play fireball sound
	fireball_sound.play()

	# Load fireball scene
	var fireball_scene = preload("res://scenes/fireball.tscn")
	var fireball = fireball_scene.instantiate()

	# Calculate spawn position (at hand level, facing direction)
	var spawn_offset_x = 12 if not animated_sprite.flip_h else -12
	var spawn_offset_y = -10  # 6 pixels below top of 32px sprite = -16 + 6 = -10 from center
	var spawn_position = global_position + Vector2(spawn_offset_x, spawn_offset_y)

	# Set fireball direction
	var direction = 1 if not animated_sprite.flip_h else -1
	fireball.initialize(spawn_position, direction)

	# Add to scene
	get_parent().add_child(fireball)

	# Track active fireball
	active_fireballs.append(fireball)
	fireball.tree_exited.connect(_on_fireball_removed.bind(fireball))

	print("DEBUG: Fireball spawned! Active count: ", active_fireballs.size())

func _on_fireball_removed(fireball):
	"""Called when a fireball is removed from the scene"""
	active_fireballs.erase(fireball)
	print("DEBUG: Fireball removed. Active count: ", active_fireballs.size())
