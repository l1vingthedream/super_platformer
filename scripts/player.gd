extends CharacterBody2D

# Power-up state system
enum PowerUpState { SMALL, BIG, FIRE, INVINCIBLE }
var current_power_state: PowerUpState = PowerUpState.SMALL
var is_growing = false

const SPEED = 300.0
const JUMP_VELOCITY = -350.0
const TURN_FRAMES = 5
const JUMP_HOLD_THRESHOLD = 0.1  # Time in seconds to distinguish short vs long jump

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var turn_timer = 0
var last_move_direction = 0  # -1 for left, 1 for right, 0 for none

# Death system
var is_dead = false

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
		velocity.x = move_toward(velocity.x, 0, SPEED * 0.5)
		move_and_slide()
		return  # Skip normal control logic

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

	var direction = Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

	# Animation logic - detect turn based on persistent direction tracking
	var is_turning = (last_move_direction == -1 and direction > 0) or (last_move_direction == 1 and direction < 0)

	# Debug output
	if direction != 0 or velocity.x != 0 or turn_timer > 0:
		print("vel.x=", velocity.x, " dir=", direction, " last_dir=", last_move_direction, " is_turning=", is_turning, " timer=", turn_timer)

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

	# Play death sound
	death_sound.play()

	# Wait for sound to finish, then reload
	await death_sound.finished
	get_tree().reload_current_scene()
