extends Camera2D

@onready var target: Node2D = get_parent().get_node("Player")

func _process(_delta):
	if target:
		global_position = target.global_position
