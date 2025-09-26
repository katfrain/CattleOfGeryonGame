extends Node

class_name CowSlot
var angle: float
var radius: float
var assigned: bool = false
var player: CharacterBody2D 

func _init(_angle: float, _radius: float, _player: CharacterBody2D) -> void:
	angle = _angle
	radius = _radius
	player = _player

func get_global_position() -> Vector2:
	return player.global_position + Vector2(cos(angle), sin(angle) * radius)
