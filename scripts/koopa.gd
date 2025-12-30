extends CharacterBody2D

# Koopa variant
enum KoopaType { GREEN, RED }
@export var koopa_type: KoopaType = KoopaType.GREEN

# Movement constants
const WALK_SPEED = 50.0  # Same speed as Goomba
const SHELL_SPEED = 200.0  # Fast shell velocity
const GRAVITY = 980.0  # Match project physics

# State machine
enum State { WALKING, SHELL_STATIONARY, SHELL_MOVING }
var current_state = State.WALKING
var movement_direction = -1  # -1 for left, 1 for right (start moving left)

# Shell mechanics
const WAKE_UP_TIME = 6.0  # Total time in shell before waking
const SHAKE_START_TIME = 3.0  # When to start shake animation
var shell_timer = 0.0
var is_shaking = false

# Player kick protection
var kicked_by_player_id: int = -1  # Store player's instance ID
var kick_immunity_timer = 0.0
const KICK_IMMUNITY_DURATION = 0.2

# Activation system (from Goomba pattern)
var is_active = false
const ACTIVATION_DISTANCE = 250.0  # Distance from camera right edge to activate
const DEACTIVATION_DISTANCE = 300.0  # Distance from camera left edge to deactivate

@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D
@onready var player_detector = $PlayerDetector
@onready var player_detector_shape = $PlayerDetector/CollisionShape2D
@onready var enemy_detector = $EnemyDetector
@onready var ledge_detector = $LedgeDetector
@onready var stomp_sound = $StompSound

func _ready():
	# Add to enemies group for shell detection
	add_to_group("enemies")

	# Configure ledge detector based on type
	if koopa_type == KoopaType.RED:
		ledge_detector.enabled = true
	else:
		ledge_detector.enabled = false

	# Enemy detector starts disabled (only used in SHELL_MOVING state)
	enemy_detector.monitoring = false

	print("DEBUG: Koopa initialized at position: ", global_position, " Type: ", koopa_type)

func _physics_process(delta):
	# Check activation based on camera position
	check_activation()

	# Only move if active
	if not is_active:
		return

	# Update kick immunity timer
	if kick_immunity_timer > 0:
		kick_immunity_timer -= delta
		if kick_immunity_timer <= 0:
			kicked_by_player_id = -1

	# Handle physics based on current state
	match current_state:
		State.WALKING:
			handle_walking_physics(delta)
		State.SHELL_STATIONARY:
			handle_shell_stationary(delta)
		State.SHELL_MOVING:
			handle_shell_moving_physics(delta)

func check_activation():
	# Get camera position
	var camera = get_viewport().get_camera_2d()
	if not camera:
		return

	var camera_x = camera.global_position.x
	var viewport_width = get_viewport_rect().size.x / camera.zoom.x
	var camera_right_edge = camera_x + viewport_width / 2.0
	var camera_left_edge = camera_x - viewport_width / 2.0

	# Activate if within range of right edge (Koopa approaching from ahead)
	if not is_active and global_position.x < camera_right_edge + ACTIVATION_DISTANCE:
		is_active = true
		print("DEBUG: Koopa activated at x=", global_position.x)

	# Deactivate and remove if too far left of camera
	if is_active and global_position.x < camera_left_edge - DEACTIVATION_DISTANCE:
		print("DEBUG: Koopa deactivated and removed at x=", global_position.x)
		queue_free()

func handle_walking_physics(delta):
	# Apply gravity
	velocity.y += GRAVITY * delta

	# Horizontal movement
	velocity.x = movement_direction * WALK_SPEED

	# Red Koopa ledge detection (only check when on ground)
	if koopa_type == KoopaType.RED and ledge_detector.enabled and is_on_floor():
		# Update raycast position based on direction
		# Cast from ahead of the Koopa's edge
		# Start from 12 pixels ahead horizontally, 8 pixels down vertically (above ground level)
		ledge_detector.position.x = 12 * movement_direction
		ledge_detector.position.y = 8
		# Cast down 20 pixels to detect floor below
		ledge_detector.target_position = Vector2(0, 20)

		# Force raycast to update with new position
		ledge_detector.force_raycast_update()

		# If not colliding with floor ahead, reverse direction
		if not ledge_detector.is_colliding():
			movement_direction *= -1
			print("DEBUG: Red Koopa detected ledge at x=", global_position.x)

	# Move and handle collisions
	move_and_slide()

	# Reverse direction on wall collision
	if is_on_wall():
		movement_direction *= -1
		print("DEBUG: Koopa hit wall, reversing direction")

	# Play walk animation
	play_walk_animation()

func handle_shell_stationary(delta):
	# Countdown timer
	shell_timer -= delta

	# Start shaking at 3 seconds remaining
	if shell_timer <= SHAKE_START_TIME and not is_shaking:
		is_shaking = true
		play_shake_animation()
		print("DEBUG: Shell shaking - waking up soon")

	# Pop out at 0 seconds
	if shell_timer <= 0:
		pop_out_of_shell()
		return

	# Still apply gravity even when stationary
	velocity.y += GRAVITY * delta
	velocity.x = 0
	move_and_slide()

func handle_shell_moving_physics(delta):
	# Apply gravity
	velocity.y += GRAVITY * delta

	# Fast horizontal movement
	velocity.x = movement_direction * SHELL_SPEED

	# Move and handle collisions
	move_and_slide()

	# Bounce off walls
	if is_on_wall():
		movement_direction *= -1
		stomp_sound.play()  # Bump sound
		print("DEBUG: Shell bounced off wall")

func enter_shell_stationary():
	"""Transition to shell stationary state"""
	current_state = State.SHELL_STATIONARY
	shell_timer = WAKE_UP_TIME
	is_shaking = false
	velocity = Vector2.ZERO

	# Play stomp sound
	stomp_sound.stream = load("res://assets/audio/stompswim.wav")
	stomp_sound.play()

	# Change to shell sprite
	play_shell_animation()

	# Shrink collision box to shell size (16x16)
	collision_shape.shape.size = Vector2(16, 16)
	player_detector_shape.shape.size = Vector2(16, 16)

	# Disable enemy detector
	enemy_detector.monitoring = false

	# Move sprite down to align bottom edge with floor
	# Walking sprite is 24px tall centered (bottom at Y+12)
	# Shell sprite is 16px tall centered (bottom at Y+8)
	# Move down by 4 pixels
	animated_sprite.position.y = 4.0

	print("DEBUG: Koopa entered shell - stationary")

func enter_shell_moving(kick_direction: int, kicker_id: int = -1):
	"""Transition to shell moving state"""
	current_state = State.SHELL_MOVING
	movement_direction = kick_direction
	velocity.x = kick_direction * SHELL_SPEED
	shell_timer = 0
	is_shaking = false

	# Play kick sound
	stomp_sound.stream = load("res://assets/audio/kickkill.wav")
	stomp_sound.play()

	# Set kick immunity
	kicked_by_player_id = kicker_id
	kick_immunity_timer = KICK_IMMUNITY_DURATION

	# Enable enemy detector for killing other enemies
	enemy_detector.monitoring = true

	# Play shell animation (no shake)
	play_shell_animation()

	print("DEBUG: Shell kicked! Moving at high speed")

func pop_out_of_shell():
	"""Return to walking state from shell"""
	current_state = State.WALKING
	shell_timer = 0
	is_shaking = false

	# Restore walk animation
	play_walk_animation()

	# Restore full collision box (16x24)
	collision_shape.shape.size = Vector2(16, 24)
	player_detector_shape.shape.size = Vector2(16, 24)

	# Disable enemy detector
	enemy_detector.monitoring = false

	# Reset sprite position
	animated_sprite.position.y = 0.0

	print("DEBUG: Koopa popped out of shell")

func play_walk_animation():
	var anim_name = "green_walk" if koopa_type == KoopaType.GREEN else "red_walk"
	if animated_sprite.animation != anim_name:
		animated_sprite.play(anim_name)
	# Flip sprite based on movement direction
	# movement_direction: -1 = left (no flip), 1 = right (flip)
	animated_sprite.flip_h = (movement_direction > 0)

func play_shell_animation():
	var anim_name = "green_shell" if koopa_type == KoopaType.GREEN else "red_shell"
	if animated_sprite.animation != anim_name:
		animated_sprite.play(anim_name)

func play_shake_animation():
	var anim_name = "green_shell_shake" if koopa_type == KoopaType.GREEN else "red_shell_shake"
	if animated_sprite.animation != anim_name:
		animated_sprite.play(anim_name)

func _on_player_detected(body):
	"""Called when player enters the Koopa's detection area"""
	if body.name != "Player":
		return

	# Check for kick immunity
	if kicked_by_player_id == body.get_instance_id() and kick_immunity_timer > 0:
		return  # Player is immune to shell they just kicked

	print("DEBUG: Player collided with Koopa! State: ", current_state)

	# Check if player is stomping (coming from above)
	var player_bottom = body.global_position.y
	if body.has_method("get_node"):
		var player_collision = body.get_node_or_null("CollisionShape2D")
		if player_collision and player_collision.shape:
			player_bottom += player_collision.shape.size.y / 2.0

	var koopa_middle = global_position.y

	# Stomp condition: player moving down and above Koopa's middle
	if body.velocity.y > 0 and player_bottom < koopa_middle:
		print("DEBUG: Player stomped Koopa!")
		on_stomped(body)
	else:
		print("DEBUG: Player hit Koopa from side")
		on_side_collision(body)

func on_stomped(player):
	"""Handle player stomping on Koopa"""
	var points = 0
	match current_state:
		State.WALKING:
			# Enter shell
			enter_shell_stationary()
			# Apply bounce to player and get points
			if player.has_method("bounce_off_enemy"):
				points = player.bounce_off_enemy()

		State.SHELL_STATIONARY:
			# Reset timer
			shell_timer = WAKE_UP_TIME
			is_shaking = false
			play_shell_animation()
			print("DEBUG: Shell timer reset by stomp")
			# Apply bounce to player and get points
			if player.has_method("bounce_off_enemy"):
				points = player.bounce_off_enemy()

		State.SHELL_MOVING:
			# Stop shell
			enter_shell_stationary()
			# Apply bounce to player and get points
			if player.has_method("bounce_off_enemy"):
				points = player.bounce_off_enemy()

	# Spawn floating score label
	if points != 0:
		GameManager.spawn_floating_score(points, global_position)

func on_side_collision(player):
	"""Handle player hitting Koopa from the side"""
	match current_state:
		State.WALKING:
			# Player takes damage
			print("DEBUG: Walking Koopa damages player")
			if player.has_method("take_damage"):
				player.take_damage()

		State.SHELL_STATIONARY:
			# Kick the shell
			var kick_direction = 1 if player.global_position.x < global_position.x else -1
			enter_shell_moving(kick_direction, player.get_instance_id())
			print("DEBUG: Player kicked shell!")

		State.SHELL_MOVING:
			# Moving shell damages player (unless immune)
			print("DEBUG: Moving shell damages player")
			if player.has_method("take_damage"):
				player.take_damage()

func _on_enemy_detected(body):
	"""Called when shell hits another enemy"""
	# Only process in SHELL_MOVING state
	if current_state != State.SHELL_MOVING:
		return

	# Check if it's an enemy
	if not body.is_in_group("enemies"):
		return

	print("DEBUG: Shell hit enemy: ", body.name)

	# Kill the enemy
	if body.has_method("squish"):
		# Goomba
		body.squish()
	elif body.has_method("enter_shell_stationary") and body != self:
		# Another Koopa (but not self)
		body.enter_shell_stationary()

	# TODO: Track kill count for combo scoring (future feature)

# Public method for Goomba-style squish compatibility
func squish():
	"""Called when hit by shell or other defeat mechanism"""
	if current_state == State.WALKING:
		enter_shell_stationary()
