extends TileMapLayer

# Tile atlas coordinates
const QUESTION_BOX_ATLAS = Vector2i(16, 2)
const EMPTY_BOX_ATLAS = Vector2i(20, 2)
const BRICK_ATLAS = Vector2i(1, 0)

# Item spawning
const ITEM_SCENE = preload("res://scenes/item.tscn")

# Animation parameters
const BOUNCE_HEIGHT = 6.0  # pixels
const BOUNCE_DURATION = 0.225  # seconds (increased by 50%: 0.15 * 1.5)

# State tracking
var hit_boxes: Dictionary = {}  # tile_coords -> bool

# References
@onready var player: CharacterBody2D = get_parent().get_node("Player")
@onready var other_layer: TileMapLayer = get_parent().get_node("TileMapLayer2") if get_parent().has_node("TileMapLayer2") else null
@onready var bump_sound = $BumpSound

func _ready():
	print("QuestionBoxes system initialized")
	print("DEBUG: TileMapLayer node name: ", name)
	print("DEBUG: Parent node: ", get_parent())
	print("DEBUG: Looking for Player at: ", get_parent().get_path())
	print("DEBUG: Player reference after @onready: ", player)

	if get_parent().has_node("Player"):
		print("DEBUG: Player node found!")
	else:
		print("DEBUG: ERROR - Player node NOT found!")
		print("DEBUG: Available nodes in parent:")
		for child in get_parent().get_children():
			print("  - ", child.name)

	if player:
		print("DEBUG: Player reference is valid: ", player.get_path())
	else:
		print("DEBUG: ERROR - Player reference is NULL!")

	# Check if there's another TileMapLayer
	if get_parent().has_node("TileMapLayer2"):
		var other_layer = get_parent().get_node("TileMapLayer2")
		print("DEBUG: WARNING - There is a TileMapLayer2! It might have question boxes too.")
		print("DEBUG: TileMapLayer2 path: ", other_layer.get_path())

func _physics_process(_delta):
	# Only check when player is hitting ceiling
	if player:
		if player.is_on_ceiling():
			print("DEBUG: Player is on ceiling!")
			check_box_collision()
	else:
		print("DEBUG: Player reference is null!")

func check_box_collision():
	# Get player's collision shape to find the top of their head
	var collision_shape = player.get_node("CollisionShape2D")
	var shape = collision_shape.shape as RectangleShape2D

	# Calculate position above player's head (player center - half height - small offset)
	var head_offset = shape.size.y / 2.0 + 2.0  # +2 pixels above head
	var head_position = player.global_position - Vector2(0, head_offset)

	# Convert to tilemap local coordinates
	var head_local_pos = to_local(head_position)

	# Convert to tile coordinates
	var tile_coords = local_to_map(head_local_pos)

	# Get the atlas coordinates of the tile
	var atlas_coords = get_cell_atlas_coords(tile_coords)

	print("DEBUG: Player global pos: ", player.global_position)
	print("DEBUG: Head position: ", head_position)
	print("DEBUG: Head local pos: ", head_local_pos)
	print("DEBUG: Tile coords: ", tile_coords)
	print("DEBUG: Atlas coords: ", atlas_coords)

	# Check if it's a question box that hasn't been hit
	if atlas_coords == QUESTION_BOX_ATLAS:
		if not hit_boxes.get(tile_coords, false):
			print("DEBUG: Hitting question box!")
			hit_box(tile_coords)
		else:
			print("DEBUG: Box already hit")
	# Check if it's an empty box (already hit)
	elif atlas_coords == EMPTY_BOX_ATLAS:
		print("DEBUG: Hitting empty box!")
		bump_sound.play()
	# Check if it's a brick tile
	elif atlas_coords == BRICK_ATLAS:
		print("DEBUG: Hitting brick tile!")
		bounce_brick(tile_coords)
	else:
		print("DEBUG: Not a special tile, atlas is: ", atlas_coords)

func hit_box(tile_coords: Vector2i):
	# Mark as hit
	hit_boxes[tile_coords] = true

	# Play bump sound
	bump_sound.play()

	print("DEBUG: Hit box at: ", tile_coords)

	# Check if this box contains an item
	var tile_data = get_cell_tile_data(tile_coords)
	var item_type = ""
	if tile_data:
		item_type = tile_data.get_custom_data("item_type")
		print("DEBUG: Item type: ", item_type)

	# Spawn item if one exists
	if item_type != "":
		spawn_item(tile_coords, item_type)

	# Immediately ERASE the tiles (make invisible) so only the bounce sprite shows
	print("DEBUG: Erasing tiles during bounce")
	erase_cell(tile_coords)

	# Also erase on the other layer if it exists
	if other_layer:
		var other_atlas = other_layer.get_cell_atlas_coords(tile_coords)
		if other_atlas == QUESTION_BOX_ATLAS:
			other_layer.erase_cell(tile_coords)
			print("DEBUG: Erased TileMapLayer2 tile")

	# Now play bounce animation (will restore empty box tile after bounce)
	bounce_box(tile_coords)

func bounce_box(tile_coords: Vector2i):
	# Create temporary sprite for animation
	var sprite = Sprite2D.new()

	# Get the tileset texture
	var atlas_source = tile_set.get_source(0) as TileSetAtlasSource
	sprite.texture = atlas_source.texture
	sprite.region_enabled = true

	# Calculate region rect for empty box tile (20,2)
	# Tileset has 1px separation: each tile occupies (16+1) pixels
	var tile_pixel_x = EMPTY_BOX_ATLAS.x * 17
	var tile_pixel_y = EMPTY_BOX_ATLAS.y * 17
	sprite.region_rect = Rect2(tile_pixel_x, tile_pixel_y, 16, 16)

	# Position sprite at tile location
	# map_to_local gives us the CENTER of the tile in local coordinates
	var tile_local_pos = map_to_local(tile_coords)

	# sprite.centered is true by default, so sprite will be centered at this position
	sprite.position = tile_local_pos

	print("DEBUG: Bounce - tile_coords: ", tile_coords, " tile_local_pos: ", tile_local_pos)

	# Add to scene (as child of TileMapLayer, so it uses local coordinates)
	add_child(sprite)

	# Create bounce animation
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)

	# Bounce up
	tween.tween_property(
		sprite,
		"position:y",
		sprite.position.y - BOUNCE_HEIGHT,
		BOUNCE_DURATION / 2.0
	)

	# Bounce down
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(
		sprite,
		"position:y",
		sprite.position.y,
		BOUNCE_DURATION / 2.0
	)

	# When animation completes: set empty box tiles and clean up sprite
	tween.tween_callback(func():
		print("DEBUG: Bounce complete - setting empty box tiles")

		# Now set the tile to empty box on THIS layer
		set_cell(tile_coords, 0, EMPTY_BOX_ATLAS)
		print("DEBUG: Set TileMapLayer to empty box at ", tile_coords)

		# Also set on the other layer if it exists
		if other_layer:
			other_layer.set_cell(tile_coords, 0, EMPTY_BOX_ATLAS)
			print("DEBUG: Set TileMapLayer2 to empty box")

		# Clean up the bounce sprite
		sprite.queue_free()
	)

func bounce_brick(tile_coords: Vector2i):
	# Immediately ERASE the brick tile (make invisible) so only the bounce sprite shows
	print("DEBUG: Erasing brick tile during bounce")
	erase_cell(tile_coords)

	# Also erase on the other layer if it exists
	if other_layer:
		var other_atlas = other_layer.get_cell_atlas_coords(tile_coords)
		if other_atlas == BRICK_ATLAS:
			other_layer.erase_cell(tile_coords)
			print("DEBUG: Erased brick on TileMapLayer2")

	# Create temporary sprite for animation
	var sprite = Sprite2D.new()

	# Get the tileset texture
	var atlas_source = tile_set.get_source(0) as TileSetAtlasSource
	sprite.texture = atlas_source.texture
	sprite.region_enabled = true

	# Calculate region rect for brick tile (1,0)
	# Tileset has 1px separation: each tile occupies (16+1) pixels
	var tile_pixel_x = BRICK_ATLAS.x * 17
	var tile_pixel_y = BRICK_ATLAS.y * 17
	sprite.region_rect = Rect2(tile_pixel_x, tile_pixel_y, 16, 16)

	# Position sprite at tile location
	# map_to_local gives us the CENTER of the tile in local coordinates
	var tile_local_pos = map_to_local(tile_coords)

	# sprite.centered is true by default, so sprite will be centered at this position
	sprite.position = tile_local_pos

	print("DEBUG: Brick bounce - tile_coords: ", tile_coords, " tile_local_pos: ", tile_local_pos)

	# Add to scene (as child of TileMapLayer, so it uses local coordinates)
	add_child(sprite)

	# Create bounce animation
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)

	# Bounce up
	tween.tween_property(
		sprite,
		"position:y",
		sprite.position.y - BOUNCE_HEIGHT,
		BOUNCE_DURATION / 2.0
	)

	# Bounce down
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(
		sprite,
		"position:y",
		sprite.position.y,
		BOUNCE_DURATION / 2.0
	)

	# When animation completes: restore brick tile and clean up sprite
	tween.tween_callback(func():
		print("DEBUG: Brick bounce complete - restoring brick tile")

		# Restore the brick tile on THIS layer
		set_cell(tile_coords, 0, BRICK_ATLAS)

		# Also restore on the other layer if it exists
		if other_layer:
			other_layer.set_cell(tile_coords, 0, BRICK_ATLAS)

		# Clean up the bounce sprite
		sprite.queue_free()
	)

func spawn_item(tile_coords: Vector2i, item_type: String):
	# Create item instance
	var item = ITEM_SCENE.instantiate()

	# Configure item type
	item.configure(item_type)

	# Position item at tile center
	var tile_center = map_to_local(tile_coords)
	var spawn_position = to_global(tile_center)

	# COIN-SPECIFIC: Spawn at TOP of box instead of center
	if item_type == "coin":
		# Tiles are 16x16, so top of tile is 8 pixels above center
		spawn_position.y -= 8.0

	item.global_position = spawn_position

	# Add to Main scene (not TileMapLayer)
	get_parent().add_child(item)

	print("DEBUG: Spawned ", item_type, " at ", item.global_position)
