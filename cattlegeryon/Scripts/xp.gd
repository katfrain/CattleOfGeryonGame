extends Node2D

var pickup_area: Area2D
var xp_amount: int = 10

func _ready() -> void:
	pickup_area = get_node("Pickup Area") as Area2D
	print("xp spawned")
	
func set_xp_amount(amt: int) -> void:
	xp_amount = amt

func _on_pickup_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("add_xp"):
		body.add_xp(xp_amount)
		queue_free()
