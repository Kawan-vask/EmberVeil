extends Node

const DEV_CONSOLE_SCENE = preload("res://Scenes/UI/dev_console.tscn")

func _ready() -> void:
	if DebugManager.DEBUG_ENABLED:
		var console := DEV_CONSOLE_SCENE.instantiate()
		add_child(console)
