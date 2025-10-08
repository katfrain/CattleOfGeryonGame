extends Node2D

func play() -> void:
	get_tree().change_scene_to_file("res://Scenes/world.tscn")
	
func exit() -> void:
	get_tree().quit(0)
	
