extends Node2D

@export var fog_textures: Array[Texture2D]
var durations = [13, 15, 17, 19, 23, 29, 32, 37]
var spread = 50
var fogblob
var cmb: Vector2i # current miniboard
var tmb: Vector2i # target miniboard (of the player, to avoid)
var cell_size: int


# Called when the node enters the scene tree for the first time.
func _ready():
	fogblob = $FogBlob
	# for every fog in the fog texture, make a parent node2d, sprite, and tween their rotation
	for t in range(fog_textures.size()):
		var rotator_node = Node2D.new()
		fogblob.add_child(rotator_node)

		var fog_sprite = Sprite2D.new()
		fog_sprite.texture = fog_textures[t]
		rotator_node.add_child(fog_sprite)
		fog_sprite.position = Vector2(randi() % spread*2 - spread, randi() % spread*2 - spread) # -spread to +spread
		
		var flip = ((randi() % 2) * 2) - 1 # -1 or +1
		
		var tween = create_tween()
		tween.set_loops()
		tween.set_parallel(true)
		tween.tween_property(rotator_node, "rotation_degrees", 360 * flip, durations[t]).as_relative()
		tween.tween_property(fog_sprite, "rotation_degrees", 360 * flip * -1, durations[t]).as_relative()
		

func update_target_miniboard(target_miniboard):
	tmb = target_miniboard

func new_game(cell_size):
	cell_size = cell_size
	cmb = Vector2i(-1, -1)
	tmb = Vector2i(-1, -1)
