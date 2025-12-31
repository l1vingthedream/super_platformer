extends Camera2D

@onready var target: Node2D = get_parent().get_node("Player")

var fixed_y: float

func _ready():
	var viewport_height = get_viewport_rect().size.y
	var ground_bottom = 0.0
	fixed_y = ground_bottom - (viewport_height / 2.0 / zoom.y)

func _process(_delta):
	if target:
		global_position.x = target.global_position.x

		# Follow player Y when entering pipe
		if target.is_entering_pipe:
			global_position.y = target.global_position.y
		else:
			# Determine which area player is in and use appropriate fixed Y
			# Main level: y < 50, Secret room: y >= 50
			if target.global_position.y >= 50:
				# Player is in secret room (y=100-400)
				# Calculate fixed Y for secret room (floor bottom at y=384)
				var viewport_height = get_viewport_rect().size.y
				var secret_room_ground = 384.0
				var secret_fixed_y = secret_room_ground - (viewport_height / 2.0 / zoom.y)
				global_position.y = secret_fixed_y
			else:
				# Player is in main level
				global_position.y = fixed_y
