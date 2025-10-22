extends Node2D

@export var heal_amount: int = 10

var player: Node2D = null

@onready var pickup_area: Area2D = $"Pickup Area"

func _ready() -> void:
	pickup_area.body_entered.connect(_on_pickup_area_body_entered)
	
func set_xp_amount(amt: int) -> void:
	heal_amount = amt

func _on_pickup_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("heal_cows"):
		body.heal_cows(heal_amount)
		if get_parent() and get_parent().has_method("remove_from_scene"):
			get_parent().remove_from_scene()
		queue_free()
		
