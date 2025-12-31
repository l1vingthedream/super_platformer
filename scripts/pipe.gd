extends Area2D

# Pipe configuration
@export var pipe_type: String = "vertical"  # "vertical" or "horizontal"
@export var pipe_direction: String = "down"  # "up", "down", "left", "right" - which way pipe faces
@export var exit_pipe: Node2D  # Reference to the exit pipe node
@export var entry_duration: float = 1.0  # How long to slide into pipe
@export var exit_duration: float = 1.0  # How long to emerge from pipe

# Node references
@onready var pipe_sound = $PipeSound

# State
var player_in_trigger = false
var warp_active = false

func _ready():
	# Connect Area2D signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D):
	if body.name == "Player":
		player_in_trigger = true
		print("DEBUG: Player entered pipe trigger zone")

func _on_body_exited(body: Node2D):
	if body.name == "Player":
		player_in_trigger = false
		print("DEBUG: Player exited pipe trigger zone")

func _process(_delta):
	if warp_active or not player_in_trigger:
		return

	# Get player reference
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	# Check if player is grounded and pressing correct input
	if not player.is_on_floor():
		return

	var should_warp = false
	if pipe_type == "vertical":
		should_warp = Input.is_action_pressed("move_down")
	elif pipe_type == "horizontal":
		should_warp = Input.is_action_pressed("move_right")

	if should_warp:
		print("DEBUG: Starting pipe warp - type: ", pipe_type)
		start_warp(player)

func start_warp(player):
	warp_active = true

	# Lock player controls
	player.enter_pipe()

	# Play pipe sound
	pipe_sound.play()

	# Entry animation
	await animate_entry(player)

	# Teleport to exit
	if exit_pipe:
		print("DEBUG: Teleporting to exit pipe at: ", exit_pipe.global_position)
		player.global_position = exit_pipe.global_position

		# Exit animation
		await animate_exit(player)
	else:
		print("WARNING: No exit pipe configured!")

	# Restore player controls
	player.exit_pipe()
	warp_active = false
	print("DEBUG: Pipe warp complete")

func animate_entry(player):
	"""Animate player entering the pipe"""
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_SINE)

	if pipe_type == "vertical":
		# Move down into pipe
		var target_y = global_position.y + 32  # Move 32 pixels down
		print("DEBUG: Animating entry - moving to y: ", target_y)
		tween.tween_property(player, "global_position:y", target_y, entry_duration)
	elif pipe_type == "horizontal":
		# Move right into pipe
		var target_x = global_position.x + 32  # Move 32 pixels right
		print("DEBUG: Animating entry - moving to x: ", target_x)
		tween.tween_property(player, "global_position:x", target_x, entry_duration)

	await tween.finished
	print("DEBUG: Entry animation complete")

func animate_exit(player):
	"""Animate player exiting from the pipe"""
	# Check exit pipe's direction to determine exit behavior
	if exit_pipe.pipe_direction == "down":
		# Downward-facing pipe - just position player at exit and let gravity take over
		print("DEBUG: Exit pipe faces down - letting gravity take over")
		player.global_position.y = exit_pipe.global_position.y + 16  # Position at pipe bottom
		# No tween needed - gravity will pull player down naturally
		return

	# For upward or horizontal exits, animate the exit
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_SINE)

	if exit_pipe.pipe_direction == "up":
		# Move up out of pipe
		var target_y = exit_pipe.global_position.y - 32  # Emerge 32 pixels above
		print("DEBUG: Animating exit - moving up to y: ", target_y)
		tween.tween_property(player, "global_position:y", target_y, exit_duration)
	elif exit_pipe.pipe_direction == "right":
		# Move right out of pipe
		var target_x = exit_pipe.global_position.x + 32  # Emerge 32 pixels to right
		print("DEBUG: Animating exit - moving right to x: ", target_x)
		tween.tween_property(player, "global_position:x", target_x, exit_duration)
	elif exit_pipe.pipe_direction == "left":
		# Move left out of pipe
		var target_x = exit_pipe.global_position.x - 32  # Emerge 32 pixels to left
		print("DEBUG: Animating exit - moving left to x: ", target_x)
		tween.tween_property(player, "global_position:x", target_x, exit_duration)

	await tween.finished
	print("DEBUG: Exit animation complete")
