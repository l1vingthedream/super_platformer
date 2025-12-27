extends CharacterBody2D

# Power-up state system
enum PowerUpState { SMALL, BIG, FIRE, INVINCIBLE }
var current_power_state: PowerUpState = PowerUpState.SMALL
var is_growing = false

# Movement constants - Momentum-based system
# Classic SMB values: Walk = 1.5px/frame, Run = 2.5px/frame @ 60fps
const WALK_MAX_SPEED = 120.0        # Maximum walking speed (1.5 * 60fps)
const RUN_MAX_SPEED = 200.0        # Maximum running speed (2.5 * 60fps) - 66.7% faster
const GROUND_ACCELERATION = 2400.0  # Acceleration on ground
const AIR_ACCELERATION = 600.0     # Reduced acceleration in air
const GROUND_FRICTION = 2500.0     # Deceleration when no input
const SKID_FRICTION = 3000.0       # Stronger friction when skidding (turning)

const JUMP_VELOCITY = -350.0
const TURN_FRAMES = 5
const JUMP_HOLD_THRESHOLD = 0.1  # Time in seconds to distinguish short vs long jump
const SKID_THRESHOLD = 200.0     # Speed threshold for skid animation

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var turn_timer = 0
var last_move_direction = 0  # -1 for left, 1 for right, 0 for none
var is_skidding = false  # Track if player is skidding

# Death system
var is_dead = false

# Flagpole sliding system
var is_sliding = false

# Damage system
var is_invulnerable = false
const INVULNERABILITY_DURATION = 2.0  # Seconds of invincibility after taking damage
const ENEMY_BOUNCE_VELOCITY = -250.0  # Upward bounce when stomping enemy

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

func _ready():
	# Make player discoverable by items
	add_to_group("player")

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

	# Trigger transition
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

func resize_collision_box(state: PowerUpState):
	match state:
		PowerUpState.SMALL:
			collision_shape.shape.size = Vector2(14, 16)
			print("DEBUG: Collision box resized to SMALL (14x16)")
		PowerUpState.BIG:
			collision_shape.shape.size = Vector2(16, 32)
			print("DEBUG: Collision box resized to BIG (16x32)")

func get_animation_name(base_name: String) -> String:
	if current_power_state == PowerUpState.BIG:
		return "big_" + base_name
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

	# Control locking during flagpole slide
	if is_sliding:
		# No player control during slide - flagpole tween controls position
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

	# Animation logic - detect turn based on persistent direction tracking
	var is_turning = is_skidding or ((last_move_direction == -1 and direction > 0) or (last_move_direction == 1 and direction < 0))

	# Debug output
	if direction != 0 or velocity.x != 0 or turn_timer > 0:
		print("vel.x=", velocity.x, " dir=", direction, " running=", is_running, " skidding=", is_skidding, " last_dir=", last_move_direction, " is_turning=", is_turning, " timer=", turn_timer)

	if is_turning:
		turn_timer = TURN_FRAMES

	# Update last_move_direction only when actively moving (not during turn animation)
	if turn_timer == 0 and direction != 0:
		last_move_direction = direction

	if not is_on_floor():
		animated_sprite.play(get_animation_name("jump"))
		turn_timer = 0
	elif turn_timer > 0:
		animated_sprite.play(get_animation_name("turn"))
		animated_sprite.flip_h = direction < 0
		turn_timer -= 1
	elif direction != 0:
		animated_sprite.play(get_animation_name("walk"))
		animated_sprite.flip_h = direction < 0
	else:
		animated_sprite.play(get_animation_name("idle"))

func die():
	is_dead = true

	# Stop player velocity
	velocity = Vector2.ZERO

	# Stop background music
	var music_player = get_tree().get_first_node_in_group("music")
	if not music_player:
		music_player = get_parent().get_node_or_null("AudioStreamPlayer")
	if music_player:
		music_player.stop()

	# Play death sound
	death_sound.play()

	# Wait for sound to finish, then reload
	await death_sound.finished
	get_tree().reload_current_scene()

func bounce_off_enemy():
	"""Apply upward bounce when player stomps on enemy"""
	velocity.y = ENEMY_BOUNCE_VELOCITY
	print("DEBUG: Player bounced off enemy")

func take_damage():
	"""Handle player taking damage from enemy"""
	# Ignore damage if already invulnerable or dead
	if is_invulnerable or is_dead:
		return

	print("DEBUG: Player taking damage! Current state: ", current_power_state)

	# If powered up (BIG, FIRE, or INVINCIBLE), revert to SMALL
	if current_power_state > PowerUpState.SMALL:
		# Power down to small
		set_power_state(PowerUpState.SMALL)
		resize_collision_box(PowerUpState.SMALL)

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
