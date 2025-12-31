extends Node2D

@onready var top_score_container = $TopScoreContainer
@onready var hud_texture = preload("res://assets/sprites/HUDs_Screens.png")

func _ready():
	print("Title screen loaded - waiting for player input")
	display_top_score()

func display_top_score():
	"""Display the top score using 6-digit number sprites"""
	# Clear any existing sprites in container
	for child in top_score_container.get_children():
		child.queue_free()

	# Format top score as 6-digit string with leading zeros
	var score_text = "%06d" % GameManager.top_score

	# Create sprite for each digit using GameManager's reusable function
	GameManager.create_text_sprites(top_score_container, score_text, Vector2(0, 0), Vector2(3, 3), hud_texture)

func _input(event):
	# Wait for jump button press
	if Input.is_action_just_pressed("jump"):
		print("Starting game...")
		get_tree().change_scene_to_file("res://scenes/life_screen.tscn")
