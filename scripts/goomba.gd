extends CharacterBody2D

# Movement constants
const WALK_SPEED = 50.0  # Slower than player's walk speed
const GRAVITY = 980.0  # Match project physics

# State
enum State { ALIVE, SQUISHED }
var current_state = State.ALIVE
var movement_direction = -1  # -1 for left, 1 for right (start moving left)

# Activation system (only move when near camera)
var is_active = false
const ACTIVATION_DISTANCE = 250.0  # Distance from camera right edge to activate
const DEACTIVATION_DISTANCE = 300.0  # Distance from camera left edge to deactivate

# Squish timer
const SQUISH_DURATION = 0.5  # Seconds before disappearing

@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D
@onready var player_detector = $PlayerDetector
@onready var stomp_sound = $StompSound

func _ready():
	# Add to enemies group for player detection
	add_to_group("enemies")
	print("DEBUG: Goomba initialized at position: ", global_position)
	print("DEBUG: Goomba collision_layer = ", collision_layer)
	print("DEBUG: Goomba is in 'enemies' group = ", is_in_group("enemies"))

func _physics_process(delta):
	# Check activation based on camera position
	check_activation()

	# Only move if active and alive
	if not is_active or current_state != State.ALIVE:
		return

	# Apply gravity
	velocity.y += GRAVITY * delta

	# Horizontal movement
	velocity.x = movement_direction * WALK_SPEED

	# Move and handle collisions
	move_and_slide()

	# Reverse direction on wall collision
	if is_on_wall():
		movement_direction *= -1
		print("DEBUG: Goomba hit wall, reversing direction")

func check_activation():
	# Get camera position
	var camera = get_viewport().get_camera_2d()
	if not camera:
		return

	var camera_x = camera.global_position.x
	var viewport_width = get_viewport_rect().size.x / camera.zoom.x
	var camera_right_edge = camera_x + viewport_width / 2.0
	var camera_left_edge = camera_x - viewport_width / 2.0

	# Activate if within range of right edge (Goomba approaching from ahead)
	if not is_active and global_position.x < camera_right_edge + ACTIVATION_DISTANCE:
		is_active = true
		print("DEBUG: Goomba activated at x=", global_position.x)

	# Deactivate and remove if too far left of camera
	if is_active and global_position.x < camera_left_edge - DEACTIVATION_DISTANCE:
		print("DEBUG: Goomba deactivated and removed at x=", global_position.x)
		queue_free()

func squish():
	"""Called when player stomps on Goomba"""
	if current_state == State.SQUISHED:
		return  # Already squished

	current_state = State.SQUISHED
	print("DEBUG: Goomba squished!")

	# Play squish sound
	if stomp_sound:
		stomp_sound.play()

	# Change sprite to flat version
	animated_sprite.play("squished")
	animated_sprite.position.y = 4.0  # Move sprite down to align bottom edge with floor

	# Stop movement
	velocity = Vector2.ZERO

	# Disable collision so player can't collide again
	collision_shape.disabled = true
	player_detector.monitoring = false

	# Remove after squish duration
	await get_tree().create_timer(SQUISH_DURATION).timeout
	queue_free()

func _on_player_detected(body):
	"""Called when player enters the Goomba's area"""
	if current_state != State.ALIVE:
		return

	if body.name != "Player":
		return

	print("DEBUG: Player collided with Goomba!")

	# Check if player is stomping (coming from above)
	var player_bottom = body.global_position.y + body.get_node("CollisionShape2D").shape.size.y / 2.0
	var goomba_middle = global_position.y

	# Stomp condition: player moving down and above Goomba's middle
	if body.velocity.y > 0 and player_bottom < goomba_middle:
		print("DEBUG: Player stomped Goomba!")
		squish()

		# Apply bounce to player and get points awarded
		var points = 0
		if body.has_method("bounce_off_enemy"):
			points = body.bounce_off_enemy()

		# Spawn floating score label
		if points != 0:
			GameManager.spawn_floating_score(points, global_position)
	else:
		print("DEBUG: Player hit Goomba from side - taking damage!")
		# Player takes damage
		if body.has_method("take_damage"):
			body.take_damage()
