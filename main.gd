extends Node

enum State {INSTRUCTIONS, PLAYER, COMPUTER, GAMEOVER}

var cell_size: int
var removables: Array
var turn: int
var grid_state: Array
var game_state: State
var target_miniboard: Vector2i # (-1, -1) means any

@export var cross_scene: PackedScene
@export var circle_scene: PackedScene


# Called when the node enters the scene tree for the first time.
func _ready():
	cell_size = $Board.texture.get_width() / 9
	new_game()


func new_game():
	for n in removables:
		n.queue_free()
	removables = []
	turn = 1
	grid_state = [[0,0,0, 0,0,0, 0,0,0],
				  [0,0,0, 0,0,0, 0,0,0],
				  [0,0,0, 0,0,0, 0,0,0],
				  [0,0,0, 0,0,0, 0,0,0],
				  [0,0,0, 0,0,0, 0,0,0],
				  [0,0,0, 0,0,0, 0,0,0],
				  [0,0,0, 0,0,0, 0,0,0],
				  [0,0,0, 0,0,0, 0,0,0],
				  [0,0,0, 0,0,0, 0,0,0]]
	game_state = State.INSTRUCTIONS
	target_miniboard = Vector2(-1, -1)
	$Fog.new_game(cell_size, 0.2)
	# hide the highlight panel bc you can play anywhere
	$HighlightPanel.visible = false


func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		match game_state:
			State.INSTRUCTIONS:
				# handled with button and signals
				pass
			State.PLAYER:
				if event.position.x < cell_size * 9:
					handle_board_click(event) 
				else:
					handle_panel_click(event)
			State.COMPUTER:
				pass
			State.GAMEOVER:
				print("todo gameover")


func handle_board_click(event):
	var grid_pos = Vector2i(event.position / cell_size)
	print(grid_pos)
	if (target_miniboard == Vector2i(-1, -1) or get_miniboard(grid_pos) == target_miniboard) and grid_state[grid_pos.y][grid_pos.x] == 0:
		take_turn(grid_pos)

func take_turn(grid_pos):
	# assumes validity has already been checked
	grid_state[grid_pos.y][grid_pos.x] = turn
	create_marker(turn, grid_pos)
	check_wins(grid_pos)
	turn *= -1
	target_miniboard = get_pos_within_miniboard(grid_pos)
	$Fog.update_target_miniboard(target_miniboard)

	# if this is the first turn, position and visible
	if not $HighlightPanel.visible:
		$HighlightPanel.position = get_miniboard(grid_pos) * cell_size * 3 + Vector2i(20, 20)
		$HighlightPanel.visible = true
	
	# tween it
	var duration = 0.2
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
#	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property($HighlightPanel, "position", Vector2(target_miniboard * cell_size * 3 + Vector2i(20,20)), duration)


func handle_panel_click(event):
	pass


func create_marker(marker_turn, grid_pos):
	var marker
	if marker_turn == 1:
		marker = cross_scene.instantiate()
	elif marker_turn == -1:
		marker = circle_scene.instantiate()
	add_child(marker)
	marker.position = grid_pos * cell_size
	removables.append(marker)


func check_wins(grid_pos):
	# check if this caused a miniboard win
	# mb stores the index of the top-left corner of the miniboard that grid_pos is part of
	var mb = get_miniboard(grid_pos) * 3
	var horizsum = grid_state[grid_pos.y][mb.x] + grid_state[grid_pos.y][mb.x + 1] + grid_state[grid_pos.y][mb.x + 2]
	var vertsum = grid_state[mb.y][grid_pos.x] + grid_state[mb.y + 1][grid_pos.x] + grid_state[mb.y + 2][grid_pos.x]
	# check both diagonals bc it's easier than figuring out if grid_pos is on a diagonal
	var down_diagsum = grid_state[mb.x][mb.y] + grid_state[mb.x + 1][mb.y + 1] + grid_state[mb.x + 2][mb.y + 2]
	var up_diagsum = grid_state[mb.x + 2][mb.y] + grid_state[mb.x + 1][mb.y + 1] + grid_state[mb.x][mb.y + 2]
	
	if horizsum == 3 or vertsum == 3 or up_diagsum == 3 or down_diagsum == 3:
		print("player wins!")
	elif horizsum == -3 or vertsum == -3 or up_diagsum == -3 or down_diagsum == -3:
		print("computer wins!")
	else:
		return
	
	# reach here if player or computer won the miniboard
	print("todo: check for big board win")
	

func _on_instructions_button_pressed():
	game_state = State.PLAYER
	$Instructions.hide_and_disable()


func get_miniboard(grid_pos):
	return Vector2i(grid_pos / 3)
func get_pos_within_miniboard(grid_pos):
	return Vector2i(grid_pos % 3)

