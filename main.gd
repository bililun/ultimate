extends Node

enum State {INSTRUCTIONS, PLAYER, COMPUTER, GAMEOVER}

var cell_size: int
var removables: Array
var turn: int
var grid_state: Array
var big_grid_state: Array # use 9 for draws
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
	big_grid_state = [[0,0,0],
					  [0,0,0],
					  [0,0,0]]
	game_state = State.INSTRUCTIONS
	target_miniboard = Vector2(-1, -1)
	$Fog.new_game(cell_size, 0.2)
	# hide the highlight panel bc you can play anywhere
	$HighlightPanel.visible = false
	$GameOver.hide_and_disable()


func game_over(winner):
	match winner:
		1:
			$GameOver.change_texture(0)
		-1:
			$GameOver.change_texture(1)
		9:
			$GameOver.change_texture(2)
	$GameOver.show_and_enable()
	$Fog.game_over()



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
	var mb = get_miniboard(grid_pos)
	# if (newgame or clicked on target or target is already decided) and that cell isn't clicked
	if (target_miniboard == Vector2i(-1, -1) or mb == target_miniboard or big_grid_state[target_miniboard.y][target_miniboard.x] != 0) and grid_state[grid_pos.y][grid_pos.x] == 0:
		take_turn(grid_pos)
	else:
		print("nope. tmb=%v, mb=%v, big_grid_state[tmb]=%d, grid_state[grid_pos]=%d" % [target_miniboard, mb, big_grid_state[target_miniboard.x][target_miniboard.y], grid_state[grid_pos.y][grid_pos.x]])


func take_turn(grid_pos):
	# assumes validity has already been checked
	grid_state[grid_pos.y][grid_pos.x] = turn
	create_marker(turn, grid_pos)
	check_wins(grid_pos)
	turn *= -1
	target_miniboard = get_pos_within_miniboard(grid_pos)
	print("tmb updated ", target_miniboard)
	$Fog.update_target_miniboard(target_miniboard)

	# if this is the first turn, position and visible
	if not $HighlightPanel.visible:
		$HighlightPanel.position = get_miniboard(grid_pos) * cell_size * 3 + Vector2i(20, 20)
		$HighlightPanel.size = Vector2.ONE * (cell_size * 3 - 40)
		$HighlightPanel.visible = true
	
	# tween it
	var duration = 0.2
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	var target_pos = Vector2(target_miniboard * cell_size * 3 + Vector2i(20,20))
	var target_size = Vector2.ONE * (cell_size * 3 - 40)
	# if you can actually play anywhere tween to big and center
	if big_grid_state[target_miniboard.y][target_miniboard.x] != 0:
		target_size = Vector2.ONE * (cell_size * 9 - 40)
		target_pos = Vector2(20, 20)
	tween.tween_property($HighlightPanel, "position", target_pos, duration)
	tween.tween_property($HighlightPanel, "size", target_size, duration)


func handle_panel_click(event):
	pass


func create_marker(marker_turn, grid_pos, big=false):
	var marker
	if marker_turn == 1:
		marker = cross_scene.instantiate()
	elif marker_turn == -1:
		marker = circle_scene.instantiate()
	$Board.add_child(marker)
	marker.position = grid_pos * cell_size
	if big:
		marker.scale *= 3
	removables.append(marker)


func check_wins(grid_pos):
	var mb = get_miniboard(grid_pos)
	var miniboard_winner = check_board_win(grid_state, grid_pos, mb * 3)
	if miniboard_winner != 0:
		big_grid_state[mb.y][mb.x] = miniboard_winner
		print("miniboard winner! mb is %v and winner is %d" %[mb, miniboard_winner])
		print(big_grid_state)
		create_marker(miniboard_winner, mb * 3, true)
		var bigboard_winner = check_board_win(big_grid_state, mb, Vector2i(0,0))
		if bigboard_winner != 0:
			game_over(bigboard_winner)


func check_board_win(grid_to_check, move_pos, top_left):
	var horizsum = grid_to_check[move_pos.y][top_left.x] + grid_to_check[move_pos.y][top_left.x + 1] + grid_to_check[move_pos.y][top_left.x + 2]
	var vertsum = grid_to_check[top_left.y][move_pos.x] + grid_to_check[top_left.y + 1][move_pos.x] + grid_to_check[top_left.y + 2][move_pos.x]
	# check both diagonals bc it's easier than figuring out if move_pos is on a diagonal
	var down_diagsum = grid_to_check[top_left.y][top_left.x] + grid_to_check[top_left.y + 1][top_left.x + 1] + grid_to_check[top_left.y + 2][top_left.x + 2]
	var up_diagsum = grid_to_check[top_left.y + 2][top_left.x] + grid_to_check[top_left.y + 1][top_left.x + 1] + grid_to_check[top_left.y][top_left.x + 2]
	
	var is_a_draw = true
	for x in range(top_left.x, top_left.x + 3):
		for y in range(top_left.y, top_left.y + 3):
			if grid_to_check[y][x] == 0:
				is_a_draw = false
	
	if horizsum == 3 or vertsum == 3 or up_diagsum == 3 or down_diagsum == 3:
		return 1
	elif horizsum == -3 or vertsum == -3 or up_diagsum == -3 or down_diagsum == -3:
		return -1
	elif is_a_draw:
		return 9
	else:
		return 0


func _on_instructions_button_pressed():
	game_state = State.PLAYER
	$Instructions.hide_and_disable()

func _on_gameover_button_pressed():
	new_game()

func get_miniboard(grid_pos):
	return Vector2i(grid_pos / 3)
func get_pos_within_miniboard(grid_pos):
	return Vector2i(grid_pos % 3)
