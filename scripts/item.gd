extends CharacterBody2D

# Item type configuration
enum ItemType { MUSHROOM, FLOWER, ONE_UP, STAR, COIN, BEANSTALK }
var item_type: ItemType = ItemType.MUSHROOM

# Physics constants
const GRAVITY = 980.0  # Match project physics
const MUSHROOM_SPEED = 100.0
const STAR_BOUNCE_VELOCITY = -300.0
const STAR_BOUNCE_HEIGHT = 32.0  # pixels from starting platform

# Pop-up animation constants
const POP_UP_DISTANCE = 16.0  # pixels
const POP_UP_DURATION = 0.3   # seconds

# State tracking
var is_popping_up = true
var movement_direction = 1  # 1 for right, -1 for left
var starting_y_position = 0.0  # For star bounce tracking
var is_collected = false

# Sprite atlas coordinates (x, y) in Items_Objects_NPCs.png
# Each tile is 16x16 with 1px separation (17px stride)
const SPRITE_COORDS = {
	ItemType.MUSHROOM: Vector2i(0, 0),
	ItemType.FLOWER: Vector2i(1, 0),
	ItemType.ONE_UP: Vector2i(0, 1),
	ItemType.STAR: Vector2i(5, 0),
	ItemType.COIN: Vector2i(9, 0),
	ItemType.BEANSTALK: Vector2i(3, 1)
}

@onready var sprite = $Sprite2D
@onready var collision_shape = $CollisionShape2D
@onready var player_detector = $PlayerDetector

func _ready():
	# Disable collision during pop-up
	collision_shape.disabled = true

	# Configure sprite region based on item type
	setup_sprite()

	# Start pop-up animation
	pop_up()

func setup_sprite():
	var coords = SPRITE_COORDS[item_type]
	# Calculate region rect (17 pixel stride: 16px tile + 1px separation)
	var pixel_x = coords.x * 17
	var pixel_y = coords.y * 17
	sprite.region_rect = Rect2(pixel_x, pixel_y, 16, 16)

	print("DEBUG: Item sprite configured - type: ", item_type, " coords: ", coords, " region: ", sprite.region_rect)

func pop_up():
	# Store starting position for star bounce calculations
	starting_y_position = global_position.y

	print("DEBUG: Item pop-up starting from: ", global_position)

	# Create tween for pop-up animation
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)

	# Move up
	tween.tween_property(
		self,
		"global_position:y",
		global_position.y - POP_UP_DISTANCE,
		POP_UP_DURATION
	)

	# When pop-up completes, enable physics and start behavior
	tween.tween_callback(on_pop_up_complete)

func on_pop_up_complete():
	is_popping_up = false

	print("DEBUG: Pop-up complete for ", item_type)

	# Special case: coin doesn't become physical
	if item_type == ItemType.COIN:
		play_coin_animation()
		return

	# Enable collision for physical items
	collision_shape.disabled = false

	# Configure physics based on item type
	match item_type:
		ItemType.MUSHROOM, ItemType.ONE_UP:
			# These move horizontally and fall with gravity
			collision_mask = 2  # Collide with world
			print("DEBUG: Mushroom/1up physics enabled")
		ItemType.FLOWER, ItemType.BEANSTALK:
			# These sit in place
			collision_mask = 0  # Don't collide with world
			print("DEBUG: Flower/Beanstalk static mode")
		ItemType.STAR:
			# Star bounces and falls
			collision_mask = 2  # Collide with world
			velocity.y = STAR_BOUNCE_VELOCITY  # Initial bounce
			print("DEBUG: Star bounce physics enabled")

func _physics_process(delta):
	if is_popping_up or is_collected:
		return

	# Apply behavior based on item type
	match item_type:
		ItemType.MUSHROOM, ItemType.ONE_UP:
			handle_mushroom_physics(delta)
		ItemType.STAR:
			handle_star_physics(delta)
		ItemType.FLOWER, ItemType.BEANSTALK:
			pass  # Static items, no physics
		ItemType.COIN:
			pass  # Coin handled by animation

func handle_mushroom_physics(delta):
	# Apply gravity
	velocity.y += GRAVITY * delta

	# Horizontal movement
	velocity.x = movement_direction * MUSHROOM_SPEED

	# Move and handle collisions
	move_and_slide()

	# Reverse direction on wall collision
	if is_on_wall():
		movement_direction *= -1
		print("DEBUG: Mushroom reversed direction")

func handle_star_physics(delta):
	# Apply gravity
	velocity.y += GRAVITY * delta

	# Move
	move_and_slide()

	# Bounce on floor
	if is_on_floor():
		velocity.y = STAR_BOUNCE_VELOCITY
		print("DEBUG: Star bounced")

func play_coin_animation():
	print("DEBUG: Playing coin animation")

	# Animate coin disappearing
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)

func _on_player_detected(body):
	if is_collected or is_popping_up:
		return

	if body.name == "Player":
		print("DEBUG: Player detected! Collecting item: ", item_type)
		collect()

func collect():
	is_collected = true

	# Apply item effect based on type
	match item_type:
		ItemType.MUSHROOM, ItemType.FLOWER:
			# TODO: Power up player (when player state system exists)
			print("Collected powerup!")
		ItemType.ONE_UP:
			# TODO: Add extra life (when life system exists)
			print("Collected 1-UP!")
		ItemType.STAR:
			# TODO: Grant invincibility (when power system exists)
			print("Collected star!")
		ItemType.COIN:
			# Already handled in play_coin_animation
			print("Collected coin!")
		ItemType.BEANSTALK:
			# TODO: Spawn beanstalk/reveal secret (future feature)
			print("Collected beanstalk!")

	# Play collection sound (to be added)

	# Remove item
	queue_free()

# Public API for spawning
func configure(type_string: String):
	match type_string:
		"mushroom", "powerup":
			item_type = ItemType.MUSHROOM
		"flower":
			item_type = ItemType.FLOWER
		"1up":
			item_type = ItemType.ONE_UP
		"star":
			item_type = ItemType.STAR
		"coin":
			item_type = ItemType.COIN
		"beanstalk":
			item_type = ItemType.BEANSTALK
		_:
			item_type = ItemType.MUSHROOM  # Default
			print("DEBUG: Unknown item type '", type_string, "' - defaulting to mushroom")

	print("DEBUG: Item configured as: ", type_string, " (", item_type, ")")
