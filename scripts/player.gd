extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -350.0
const TURN_FRAMES = 20

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var turn_timer = 0

@onready var animated_sprite = $AnimatedSprite2D

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var was_moving_right = velocity.x > 0
	var was_moving_left = velocity.x < 0

	var direction = Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

	# Animation logic
	var is_turning = (was_moving_left and direction > 0) or (was_moving_right and direction < 0)

	# Debug output
	if direction != 0 or velocity.x != 0 or turn_timer > 0:
		print("vel.x=", velocity.x, " dir=", direction, " was_L=", was_moving_left, " was_R=", was_moving_right, " is_turning=", is_turning, " timer=", turn_timer)

	if is_turning:
		turn_timer = TURN_FRAMES

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
