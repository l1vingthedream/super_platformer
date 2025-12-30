extends CanvasLayer

# Container references
@onready var player_name_container = $Control/PlayerNameContainer
@onready var score_container = $Control/ScoreContainer
@onready var coins_container = $Control/CoinsContainer
@onready var world_label_container = $Control/WorldLabelContainer
@onready var world_value_container = $Control/WorldValueContainer
@onready var time_label_container = $Control/TimeLabelContainer
@onready var time_value_container = $Control/TimeValueContainer
@onready var coin_sprite = $Control/CoinsContainer/CoinSprite

# Texture reference
@onready var hud_texture = preload("res://assets/sprites/HUDs_Screens.png")

# Coin animation
const COIN_FRAMES = [
	Rect2(0, 156, 8, 8),
	Rect2(10, 156, 8, 8),
	Rect2(20, 156, 8, 8),
	Rect2(30, 156, 8, 8)
]
var coin_frame_index = 0
var coin_animation_timer = 0.0
const COIN_FRAME_DURATION = 0.15  # 150ms per frame

# Sprite scale and spacing constants
const SPRITE_SCALE = Vector2(3, 3)
const LETTER_WIDTH = 8  # Width of each letter in pixels (before scaling)
const LETTER_SPACING = 1  # Gap between letters in pixels (before scaling)

func _ready():
	# Initial display setup
	update_player_name()
	update_score(GameManager.score)
	update_coins(GameManager.coins)
	update_world()
	update_time(GameManager.time)

	# Connect to GameManager signals
	GameManager.coin_collected.connect(_on_coin_collected)
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.time_changed.connect(_on_time_changed)

func _process(delta):
	# Animate coin sprite
	coin_animation_timer += delta
	if coin_animation_timer >= COIN_FRAME_DURATION:
		coin_animation_timer = 0.0
		coin_frame_index = (coin_frame_index + 1) % COIN_FRAMES.size()
		coin_sprite.region_rect = COIN_FRAMES[coin_frame_index]

func update_player_name():
	"""Display player name"""
	clear_container(player_name_container)
	create_text_sprites(player_name_container, GameManager.PLAYER_NAME)

func update_score(new_score: int):
	"""Display score with 6 digits"""
	clear_container(score_container)
	var score_text = "%06d" % new_score
	create_text_sprites(score_container, score_text)

func update_coins(new_coins: int):
	"""Display coin count with 'x' and 2 digits"""
	# Clear everything except the coin sprite
	for child in coins_container.get_children():
		if child != coin_sprite:
			child.queue_free()

	# Position coin sprite at the start
	coin_sprite.position = Vector2(0, 0)

	# Calculate starting position for 'x' after coin sprite
	# Coin sprite is 8px wide, scaled by 3 = 24px, plus spacing
	var x_pos = (LETTER_WIDTH + LETTER_SPACING) * SPRITE_SCALE.x

	# Add "x" character at (117, 114, 8, 8)
	var x_sprite = Sprite2D.new()
	x_sprite.texture = hud_texture
	x_sprite.region_enabled = true
	x_sprite.region_rect = Rect2(117, 114, 8, 8)
	x_sprite.scale = SPRITE_SCALE
	x_sprite.position = Vector2(x_pos, 0)
	coins_container.add_child(x_sprite)

	# Add coin count (2 digits) after the 'x'
	var coins_text = "%02d" % new_coins
	var digit_start_pos = x_pos + (LETTER_WIDTH + LETTER_SPACING) * SPRITE_SCALE.x
	create_text_sprites(coins_container, coins_text, digit_start_pos)

func update_world():
	"""Display world label and level number"""
	# Clear both containers
	clear_container(world_label_container)
	clear_container(world_value_container)

	# Display "WORLD" label
	create_text_sprites(world_label_container, "WORLD")

	# Display level value below (e.g., "1-1")
	var level_text = "%d-%d" % [GameManager.world, GameManager.level]
	create_text_sprites(world_value_container, level_text)

func update_time(new_time: int):
	"""Display TIME label and time value"""
	# Clear both containers
	clear_container(time_label_container)
	clear_container(time_value_container)

	# Display "TIME" label
	create_text_sprites(time_label_container, "TIME")

	# Display time value below (e.g., "400")
	var time_text = "%03d" % new_time
	create_text_sprites(time_value_container, time_text)

func create_text_sprites(container: Node2D, text: String, start_x: float = 0.0):
	"""Create letter sprites with proper spacing"""
	for i in range(text.length()):
		var letter = text[i]
		var sprite = Sprite2D.new()
		sprite.texture = hud_texture
		sprite.region_enabled = true
		sprite.region_rect = GameManager.get_letter_region(letter)
		sprite.scale = SPRITE_SCALE

		# Calculate position with spacing
		var x_offset = start_x + i * (LETTER_WIDTH + LETTER_SPACING) * SPRITE_SCALE.x
		sprite.position = Vector2(x_offset, 0)

		container.add_child(sprite)

func clear_container(container: Node):
	"""Remove all children from a container"""
	for child in container.get_children():
		child.queue_free()

# Signal handlers
func _on_coin_collected(new_total: int):
	update_coins(new_total)

func _on_score_changed(new_score: int):
	update_score(new_score)

func _on_time_changed(new_time: int):
	update_time(new_time)
