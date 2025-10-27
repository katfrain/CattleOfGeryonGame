extends Node2D

func play() -> void:
	cow_manager.reset_manager()
	get_tree().change_scene_to_file("res://Scenes/world.tscn")
	
func exit() -> void:
	get_tree().quit(0)
	
func credits() -> void:
	get_tree().change_scene_to_file("res://Scenes/credits.tscn")
