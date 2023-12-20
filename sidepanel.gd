extends Panel

@export var singleplayer_textures: Array[Texture2D]
@export var twoplayer_textures: Array[Texture2D]

var textures: Array[Texture2D]
var current_texture: int
var default_time: int


func new_game(single_player, time_per_turn):
	textures = singleplayer_textures if single_player else twoplayer_textures
	assert(textures.size() > 0)
	current_texture = 0
	$TurnSprite.texture = textures[current_texture]
	
	$Timer.stop()
	default_time = time_per_turn
		
func toggle_turn():
	current_texture = (current_texture + 1) % textures.size()
	$TurnSprite.texture = textures[current_texture]

func start_timer(time=default_time):
	$Timer.set_wait_time(time+1)
	$Timer.start()

func game_over():
	$Timer.stop()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	$Label.text = "%d" % $Timer.time_left
