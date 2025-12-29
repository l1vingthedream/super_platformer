extends CharacterBody2D

# Physics constants
const HORIZONTAL_SPEED = 250.0  # Faster than player walking
const BOUNCE_VELOCITY = -300.0  # Upward velocity on floor bounce
const GRAVITY = 980.0  # Match project gravity

# State
var direction = 1  # 1 for right, -1 for left
var has_hit = false

@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D
@onready var enemy_detector = $EnemyDetector

func _ready():
	# Start spinning animation
	animated_sprite.play("spin")
	print("DEBUG: Fireball created")
	print("DEBUG: Fireball collision_layer = ", collision_layer)
	print("DEBUG: Fireball collision_mask = ", collision_mask)
	print("DEBUG: EnemyDetector collision_layer = ", enemy_detector.collision_layer)
	print("DEBUG: EnemyDetector collision_mask = ", enemy_detector.collision_mask)
	print("DEBUG: EnemyDetector monitoring = ", enemy_detector.monitoring)

func initialize(spawn_pos: Vector2, spawn_direction: int):
	"""Initialize fireball with position and direction"""
	global_position = spawn_pos
	direction = spawn_direction
	velocity.x = direction * HORIZONTAL_SPEED
	velocity.y = 0  # Start with no vertical velocity

func _physics_process(delta):
	if has_hit:
		return

	# Apply gravity
	velocity.y += GRAVITY * delta

	# Maintain horizontal velocity
	velocity.x = direction * HORIZONTAL_SPEED

	# Move and check collisions
	move_and_slide()

	# Bounce on floor
	if is_on_floor():
		velocity.y = BOUNCE_VELOCITY
		print("DEBUG: Fireball bounced")

	# Disappear on wall collision
	if is_on_wall():
		print("DEBUG: Fireball hit wall")
		explode()
		return

	# Remove if off screen (fallback)
	var camera = get_viewport().get_camera_2d()
	if camera:
		var camera_x = camera.global_position.x
		var viewport_width = get_viewport_rect().size.x / camera.zoom.x
		if global_position.x < camera_x - viewport_width or global_position.x > camera_x + viewport_width:
			queue_free()

func _on_enemy_detected(body):
	"""Called when fireball hits an enemy"""
	if has_hit:
		return

	if not body.is_in_group("enemies"):
		return

	print("DEBUG: Fireball hit enemy: ", body.name)

	# Defeat the enemy
	if body.has_method("squish"):
		body.squish()
	elif body.has_method("enter_shell_stationary"):
		body.enter_shell_stationary()

	# Explode
	explode()

func explode():
	"""Create poof explosion and remove fireball"""
	has_hit = true

	# Disable collision
	collision_shape.disabled = true
	enemy_detector.monitoring = false

	# Spawn poof explosion
	var poof_scene = preload("res://scenes/fireball_poof.tscn")
	var poof = poof_scene.instantiate()
	poof.global_position = global_position
	get_parent().add_child(poof)

	# Remove fireball
	queue_free()
