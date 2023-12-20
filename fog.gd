extends Node2D

@export var fog_textures: Array[Texture2D]
var durations = [15,17,19,23,29,31,32,37,41]
var spread = 30
var fogblob
var prevmb: Vector2i # miniboard we're tweening away from
var destmb: Vector2i # miniboard we're tweening towards
var tmb: Vector2i # target miniboard (of the player, to avoid)
var cell_size: int
var meander_duration = 16
var collide_duration = 0.2 # if you're running into the player's target miniboard

var blob_tween
var scale_tween
var orig_scale
var inner_tweens: Array
var spriteglitcher = preload("res://spriteglitcher.gd")


# Called when the node enters the scene tree for the first time.
func _ready():
	fogblob = $FogBlob
	orig_scale = fogblob.scale
	create_inner_tweens()


func create_inner_tweens():
	# for every fog in the fog texture, make a parent node2d, sprite, and tween their rotation
	for t in range(fog_textures.size()):
		var rotator_node = Node2D.new()
		fogblob.add_child(rotator_node)

		var fog_sprite = spriteglitcher.new()
		fog_sprite.texture = fog_textures[t]
		fog_sprite.textures = fog_textures # can glitch into any of the textures
		rotator_node.add_child(fog_sprite)
		fog_sprite.position = Vector2(randi() % spread*2 - spread, randi() % spread*2 - spread) # -spread to +spread
		
		var flip = ((randi() % 2) * 2) - 1 # -1 or +1
		
		var tween = create_tween()
		tween.set_loops()
		tween.set_parallel(true)
		tween.tween_property(rotator_node, "rotation_degrees", 360 * flip, durations[t]).as_relative()
		tween.tween_property(fog_sprite, "rotation_degrees", 360 * flip * -1, durations[t]).as_relative()
		inner_tweens.append(tween)
		

func update_target_miniboard(target_miniboard):
	var old_tmb = tmb
	tmb = target_miniboard
	
	if destmb == Vector2i(-1, -1):
		enter_fogblob()
		
	if prevmb == tmb:
		# zoom to destmb
		blob_tween.kill()
		create_blob_tween(collide_duration)
	
	if destmb == tmb:
		# uh oh collision! get out
		var diff = snap_and_sign(tmb - old_tmb)
		print("dest is tmb. diff: ", diff)
		# first try to match direction
		var newdestmb = destmb + diff
		if not is_in_bounds(newdestmb):
			# tmb is either a side being approached perpendicularly, or a corner
			var options = get_options(tmb)
			# there must be at least 2 options
			if diff in options:
				options.remove(diff)
			newdestmb = destmb + options[randi() % options.size()]
			
		destmb = newdestmb
		blob_tween.kill()
		create_blob_tween(collide_duration)


func enter_fogblob():
		var r = randf()
		if r < 0.25:
			destmb = Vector2i(randi() % 3, 0)
			prevmb = destmb + Vector2i.UP
		elif r < 0.5:
			destmb = Vector2i(randi() % 3, 2)
			prevmb = destmb + Vector2i.DOWN
		elif r < 0.75:
			destmb = Vector2i(0, randi() % 3)
			prevmb = destmb + Vector2i.LEFT
		else:
			destmb = Vector2i(2, randi() % 3)
			prevmb = destmb + Vector2i.RIGHT
		
		fogblob.position = get_coords(prevmb)
		fogblob.scale = orig_scale / 2
		scale_tween = create_tween()
		scale_tween.set_trans(Tween.TRANS_CUBIC)
		scale_tween.tween_property(fogblob, "scale", orig_scale, meander_duration * 10.0)
		fogblob.visible = true
		create_blob_tween(meander_duration)
		

func meander():
	# callbacked when the previous meander finishes
	var options = get_options(destmb)
	
	var chosen = options[randi() % options.size()]
	# try to avoid prev mb and definitely don't go to the player's target miniboard
	while (destmb + chosen == prevmb and randf() < 0.99) or destmb + chosen == tmb:
		chosen = options[randi() % options.size()]
	prevmb = destmb
	destmb += chosen
	
	create_blob_tween(meander_duration)


func new_game(_cell_size, _collide_duration):
	cell_size = _cell_size
	collide_duration = _collide_duration
	prevmb = Vector2i(-1, -1)
	destmb = Vector2i(-1, -1)
	tmb = Vector2i(-1, -1)
	fogblob.visible = false


func game_over():
	for t in inner_tweens:
		t.kill()
	blob_tween.kill()
	scale_tween.kill()


func get_coords(mb):
	return Vector2(mb * cell_size * 3)

func get_options(mb):
	var options = []
	if mb.y != 0:
		options.append(Vector2i.UP)
	if mb.y != 2:
		options.append(Vector2i.DOWN)
	if mb.x != 0:
		options.append(Vector2i.LEFT)
	if mb.x != 2:
		options.append(Vector2i.RIGHT)
	return options

func is_in_bounds(mb):
	return -1 < mb.x and mb.x < 3 and -1 < mb.y and mb.y < 3
	
func snap_and_sign(vector):
	# returns one of 8 cardinal directions
	# intentionally not evenly distributed
	return Vector2i(Vector2(vector).normalized().snapped(Vector2.ONE))

func create_blob_tween(duration):
	# tween it!
	blob_tween = create_tween()
	blob_tween.tween_property(fogblob, "position", get_coords(destmb), duration)
	blob_tween.tween_callback(meander)
	pass
