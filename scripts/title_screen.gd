extends Node2D

func _ready():
	print("Title screen loaded - waiting for player input")

func _input(event):
	# Wait for jump button press
	if Input.is_action_just_pressed("jump"):
		print("Starting game...")
		get_tree().change_scene_to_file("res://scenes/life_screen.tscn")
