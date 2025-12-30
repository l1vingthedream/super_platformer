extends Sprite2D

# Point value sprite regions in Items_Objects_NPCs.png
# Starting at col=220, row=0, with 1px vertical separation
const SCORE_SPRITES = {
	100: Rect2(220, 0, 16, 16),
	200: Rect2(220, 17, 16, 16),
	400: Rect2(220, 34, 16, 16),
	500: Rect2(220, 51, 16, 16),
	800: Rect2(220, 68, 16, 16),
	1000: Rect2(220, 85, 16, 16),
	2000: Rect2(220, 102, 16, 16),
	4000: Rect2(220, 119, 16, 16),
	5000: Rect2(220, 136, 16, 16),
	8000: Rect2(220, 153, 16, 16),
	-1: Rect2(220, 170, 16, 16)  # 1UP sprite
}

const FLOAT_DURATION = 0.5  # Duration in seconds
const FLOAT_DISTANCE = 30.0  # How far to float upward

func _ready():
	# Start the floating animation immediately
	float_and_fade()

func set_score(points: int):
	"""Set the sprite region based on points value"""
	if SCORE_SPRITES.has(points):
		region_rect = SCORE_SPRITES[points]
	else:
		# Default to 100 if points value not found
		region_rect = SCORE_SPRITES[100]

func float_and_fade():
	"""Tween the label upward and fade it out"""
	var tween = create_tween()
	tween.set_parallel(true)  # Run both tweens simultaneously

	# Float upward
	tween.tween_property(self, "position", position + Vector2(0, -FLOAT_DISTANCE), FLOAT_DURATION)

	# Fade out
	tween.tween_property(self, "modulate:a", 0.0, FLOAT_DURATION)

	# Clean up when done
	tween.finished.connect(queue_free)
