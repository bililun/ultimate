extends Control

signal button_pressed

@export var textures: Array[Texture2D]

func _on_button_pressed():
	button_pressed.emit()


func change_texture(index):
	if not (-1 < index and index < textures.size()):
		return false
	for child in get_children():
		if child is Sprite2D:
			child.texture = textures[index]
			return true
	return false


func hide_and_disable():
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED


func show_and_enable():
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
