extends Node

enum State {INSTRUCTIONS, PLAYER, PLAYER2, COMPUTER, GAMEOVER}

var cell_size: int
var removables: Array
var turn: int
var grid_state: Array
var big_grid_state: Array # use 9 for draws
var game_state: State
var target_miniboard: Vector2i # (-1, -1) means any

var single_player = true
var time_per_turn = 12

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
	$Instructions.show_and_enable()
	target_miniboard = Vector2(-1, -1)
	$SidePanel.new_game(single_player, time_per_turn)
	$Fog.new_game(cell_size, 0.2)
	# hide the highlight panel bc you can play anywhere
	$HighlightPanel.visible = false
	$GameOver.hide_and_disable()


func game_over(winner):
	game_state = State.GAMEOVER
	match winner:
		1:
			$GameOver.change_texture(0)
		-1:
			$GameOver.change_texture(1)
		9:
			$GameOver.change_texture(2)
	$GameOver.show_and_enable()
	$Fog.game_over()
	$SidePanel.game_over()


func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		match game_state:
			State.INSTRUCTIONS:
				# handled with button and signal
				pass
			State.PLAYER:
				if event.position.x < cell_size * 9:
					handle_board_click(event) 
				else:
					handle_panel_click(event)
			State.PLAYER2:
				if event.position.x < cell_size * 9:
					handle_board_click(event) 
				else:
					handle_panel_click(event)
			State.COMPUTER:
				pass
			State.GAMEOVER:
				# handled with button and signal
				pass


func handle_board_click(event):
	if not (game_state == State.PLAYER or game_state == State.PLAYER2):
		return
	
	var grid_pos = Vector2i(event.position / cell_size)
	var mb = get_miniboard(grid_pos)
	# if (newgame or clicked on target or target is already decided) and that cell isn't clicked
	if (target_miniboard == Vector2i(-1, -1) or mb == target_miniboard or big_grid_state[target_miniboard.y][target_miniboard.x] != 0) and grid_state[grid_pos.y][grid_pos.x] == 0:
		take_turn(grid_pos)
	else:
		print("nope. tmb=%v, mb=%v, big_grid_state[tmb]=%d, grid_state[grid_pos]=%d" % [target_miniboard, mb, big_grid_state[target_miniboard.y][target_miniboard.x], grid_state[grid_pos.y][grid_pos.x]])


func take_turn(grid_pos):
	# assumes validity has already been checked
	grid_state[grid_pos.y][grid_pos.x] = turn
	create_marker(turn, grid_pos)
	check_wins(grid_pos)
	toggle_turn()
	target_miniboard = get_pos_within_miniboard(grid_pos)
	$Fog.update_target_miniboard(target_miniboard)
	
	$Board.slam()

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
	# if you can actually play anywhere, tween to big and center
	if big_grid_state[target_miniboard.y][target_miniboard.x] != 0:
		target_size = Vector2.ONE * (cell_size * 9 - 40)
		target_pos = Vector2(20, 20)
	tween.tween_property($HighlightPanel, "position", target_pos, duration)
	tween.tween_property($HighlightPanel, "size", target_size, duration)


func computer_take_turn():
	if not single_player or game_state != State.COMPUTER:
		return
	var grid_pos = choose_smart_move()
	take_turn(grid_pos)


func handle_panel_click(_event):
	pass


func create_marker(marker_turn, grid_pos, big=false):
	# instantiate a circle or cross node
	assert(grid_pos != null)
	var marker
	if marker_turn == 1:
		marker = cross_scene.instantiate()
	elif marker_turn == -1:
		marker = circle_scene.instantiate()
	else:
		return
	$Board.add_child(marker)
	marker.position = grid_pos * cell_size
	if big:
		marker.scale *= 3
	removables.append(marker)


func check_wins(grid_pos):
	# checks for wins after a move at grid_pos
	# and calls game_over if game ends
	var mb = get_miniboard(grid_pos)
	var miniboard_winner = check_board_win(grid_state, grid_pos, mb * 3)
	if miniboard_winner != 0:
		big_grid_state[mb.y][mb.x] = miniboard_winner
		create_marker(miniboard_winner, mb * 3, true)
		var bigboard_winner = check_board_win(big_grid_state, mb, Vector2i(0,0))
		if bigboard_winner != 0:
			game_over(bigboard_winner)


func check_board_win(grid_to_check, move_pos, top_left):
	# checks for a win in grid_to_check offset by top_left after a move at move_pos
	# returns -1, 0, 1, or 9 for an O win, nothing, X win, or draw
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


func choose_smart_move():
	# finds all possible moves then picks a good one
	# options stores Vector3s: x, y, score
	var options = []
	if target_miniboard == Vector2i(-1, -1) or big_grid_state[target_miniboard.y][target_miniboard.x] != 0:
		# if the whole board is available
		for y in range(grid_state.size()):
			for x in range(grid_state[y].size()):
				var mb = get_miniboard(Vector2i(x,y))
				if big_grid_state[mb.y][mb.x] == 0 and grid_state[y][x] == 0:
					options.append(Vector3i(x,y, 0))
	else:
		# only look at target_miniboard
		for y in range(target_miniboard.y * 3, target_miniboard.y * 3 + 3):
			for x in range(target_miniboard.x * 3, target_miniboard.x * 3 + 3):
				if grid_state[y][x] == 0:
					options.append(Vector3i(x,y, 0))
	assert(options.size() > 0)
	
	# give all the options scores
	# use indexing so we actually change the vectors
	for o in range(options.size()):
		var option = options[o]
		var v2i = Vector2i(option.x, option.y)
		var mb = get_miniboard(v2i)
		# temporarily alter grid_state
		grid_state[option.y][option.x] = -1
		var would_win = check_board_win(grid_state, v2i, mb * 3) == -1
		grid_state[option.y][option.x] = 1
		var would_block = check_board_win(grid_state, v2i, mb * 3) == 1
		grid_state[option.y][option.x] = 0
		var sends_to = get_pos_within_miniboard(v2i)
		var would_send_free = big_grid_state[sends_to.y][sends_to.x] != 0
		
		if would_win:
			options[o].z = 150
		elif would_block:
			options[o].z = 50
		
		if would_send_free:
			options[o].z -= 75
			
	# choose the one with the highest score
	var best_options = []
	var best_z = -INF
	for option in options:
		if option.z > best_z:
			best_options = [option]
			best_z = option.z
		elif option.z == best_z:
			best_options.append(option)
	# choose randomly between best options
	var grid_pos = best_options[randi() % best_options.size()]
	grid_pos = Vector2i(grid_pos.x, grid_pos.y)
	return grid_pos

func choose_random_move():
	# extremely advanced algorithm
	var grid_pos = Vector2i(randi() % 9, randi() % 9)
	var mb = get_miniboard(grid_pos)
	while not (
		(target_miniboard == Vector2i(-1,-1) # anything on first move
		or mb == target_miniboard # playing in correct target
		or big_grid_state[target_miniboard.y][target_miniboard.x] != 0 # free range
		) 
		and grid_state[grid_pos.y][grid_pos.x] == 0 # empty cell
		and big_grid_state[mb.y][mb.x] == 0 # mb undecided
		):
		grid_pos = Vector2i(randi() % 9, randi() % 9)
		mb = get_miniboard(grid_pos)
	return grid_pos

func toggle_turn():
	turn *= -1
	if game_state == State.COMPUTER:
		game_state = State.PLAYER
	elif game_state == State.PLAYER:
		if single_player:
			game_state = State.COMPUTER
			create_tween().tween_callback(computer_take_turn).set_delay(1)
		else:
			game_state = State.PLAYER2
	elif game_state == State.PLAYER2:
		game_state = State.PLAYER
	else:
		return
	
	$SidePanel.toggle_turn()
	$SidePanel.start_timer()

func _on_instructions_button_pressed():
	game_state = State.PLAYER
	$Instructions.hide_and_disable()
	$SidePanel.start_timer()

func _on_gameover_button_pressed():
	new_game()

func _on_timer_timeout():
	var warn_tween = create_tween()
	warn_tween.set_trans(Tween.TRANS_CUBIC)
	warn_tween.tween_property($WarningPanel, "modulate:a", 0.1, 0.1)
	warn_tween.tween_property($WarningPanel, "modulate:a", 0, 0.1)
	toggle_turn()

func get_miniboard(grid_pos):
	return Vector2i(grid_pos / 3)
func get_pos_within_miniboard(grid_pos):
	return Vector2i(grid_pos % 3)
