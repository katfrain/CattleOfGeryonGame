extends Node

var cow_speed: float = 50

func upgrade_cow_speed(amount: float) -> void:
	cow_speed *= amount
