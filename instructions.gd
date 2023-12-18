extends Control

signal button_pressed

func _on_button_pressed():
	button_pressed.emit()


func hide_and_disable():
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	pass
