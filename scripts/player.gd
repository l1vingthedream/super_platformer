extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -350.0
const TURN_FRAMES = 5

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var turn_timer = 0
var last_move_direction = 0  # -1 for left, 1 for right, 0 for none

@onready var animated_sprite = $AnimatedSprite2D

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

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
