extends Sprite2D

@export var slam_duration = 0.03
@export var num_slams: int = 2
@export var slam_intensity: int = 8

var t: Tween

func slam():
	if t != null:
		t.kill()
	t = create_tween()
	for s in range(num_slams):
		t.tween_property(self, "position", Vector2(randi() % slam_intensity - slam_intensity/2.0, randi() % slam_intensity - slam_intensity/2.0), slam_duration)
	# reset
	t.tween_property(self, "position", Vector2.ZERO, 0.1)
