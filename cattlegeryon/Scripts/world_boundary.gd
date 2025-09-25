extends Area2D


func _on_body_exited(body: Node2D) -> void:
	print("Body entered! ", body)
	if body.is_in_group("cows"):
		body.queue_free()
