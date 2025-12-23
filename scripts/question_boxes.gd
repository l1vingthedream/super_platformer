extends TileMapLayer

# Tile atlas coordinates
const QUESTION_BOX_ATLAS = Vector2i(16, 2)
const EMPTY_BOX_ATLAS = Vector2i(20, 2)

# Animation parameters
const BOUNCE_HEIGHT = 6.0  # pixels
const BOUNCE_DURATION = 0.225  # seconds (increased by 50%: 0.15 * 1.5)

# State tracking
var hit_boxes: Dictionary = {}  # tile_coords -> bool

# References
@onready var player: CharacterBody2D = get_parent().get_node("Player")
@onready var other_layer: TileMapLayer = get_parent().get_node("TileMapLayer2") if get_parent().has_node("TileMapLayer2") else null

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
	else:
		print("DEBUG: Not a question box, atlas is: ", atlas_coords)

func hit_box(tile_coords: Vector2i):
	# Mark as hit
	hit_boxes[tile_coords] = true

	print("DEBUG: Before set_cell - Atlas at ", tile_coords, ": ", get_cell_atlas_coords(tile_coords))

	# Change tile to empty box on THIS layer
	set_cell(tile_coords, 0, EMPTY_BOX_ATLAS)

	print("DEBUG: After set_cell - Atlas at ", tile_coords, ": ", get_cell_atlas_coords(tile_coords))
	print("DEBUG: set_cell called with source_id=0, atlas_coords=", EMPTY_BOX_ATLAS)

	# Also change tile on the other layer if it exists
	if other_layer:
		var other_atlas = other_layer.get_cell_atlas_coords(tile_coords)
		print("DEBUG: TileMapLayer2 before - Atlas at ", tile_coords, ": ", other_atlas)
		if other_atlas == QUESTION_BOX_ATLAS:
			other_layer.set_cell(tile_coords, 0, EMPTY_BOX_ATLAS)
			print("DEBUG: TileMapLayer2 after - Atlas at ", tile_coords, ": ", other_layer.get_cell_atlas_coords(tile_coords))
		else:
			print("DEBUG: TileMapLayer2 doesn't have question box at this position")

	# Play bounce animation
	bounce_box(tile_coords)

	# Debug
	print("Hit box at: ", tile_coords)

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

	# Clean up sprite when animation completes
	tween.tween_callback(sprite.queue_free)
