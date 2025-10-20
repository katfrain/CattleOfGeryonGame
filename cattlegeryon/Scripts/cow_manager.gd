extends Node

var cow_speed: float = 70

func upgrade_cow_speed(amount: float) -> void:
	cow_speed *= amount
