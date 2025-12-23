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
		global_position.y = fixed_y
