extends CharacterBody2D

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
@onready var death_sound = $DeathSound
@onready var jump_sound = $JumpSound
@onready var jump_small_sound = $JumpSmallSound

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

		# Start with small jump sound (assume quick tap)
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
		animated_sprite.play("jump")
		turn_timer = 0
	elif turn_timer > 0:
		animated_sprite.play("turn")
		animated_sprite.flip_h = direction < 0
		turn_timer -= 1
	elif direction != 0:
		animated_sprite.play("walk")
		animated_sprite.flip_h = direction < 0
	else:
		animated_sprite.play("idle")

func die():
	is_dead = true

	# Stop player velocity
	velocity = Vector2.ZERO

	# Play death sound
	death_sound.play()

	# Wait for sound to finish, then reload
	await death_sound.finished
	get_tree().reload_current_scene()
