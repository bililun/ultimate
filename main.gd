extends Node

var cell_size: int

@export var cross_scene: PackedScene
@export var circle_scene: PackedScene


# Called when the node enters the scene tree for the first time.
func _ready():
	cell_size = $Board.get_width() / 9
	
func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if event.position.x < cell_size * 9:
			handle_board_click(event) 
		else:
			handle_panel_click(event)
			
func handle_board_click(event):
	print("todo: handle board click")
	pass

func handle_panel_click(event):
	pass

func new_game():
	print("todo: implement new game")
	pass
