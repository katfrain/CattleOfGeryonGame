extends Node

var cow_speed: float
var cow_health: float

const BASE_COW_SPEED: float = 70.0
const BASE_COW_HEALTH: float = 200.0

func _ready() -> void:
	reset_manager()
	print(get_parent())

func upgrade_cow_speed(amount: float) -> void:
	cow_speed *= amount
	
func upgrade_cow_health(amount: float) -> void:
	cow_health *= amount
	
func reset_manager():
	cow_speed = BASE_COW_SPEED
	cow_health = BASE_COW_HEALTH
	
