extends Sprite2D

@export var textures: Array[Texture2D]
@export var duration = 0.05
@export var min_wait = 1.0
@export var max_wait = 2.0
var diff = max_wait - min_wait
var normal_texture
var t: Tween


# Called when the node enters the scene tree for the first time.
func _ready():
	normal_texture = texture
	if textures.size() > 0:
		create_tween().tween_callback( glitch ).set_delay(randf() * diff + min_wait)


func glitch():
	texture = textures[randi() % textures.size()]
	t = create_tween()
	t.tween_callback(revert).set_delay(duration)
	t.tween_callback( glitch ).set_delay(randf() * diff + min_wait)


func revert():
	texture = normal_texture
