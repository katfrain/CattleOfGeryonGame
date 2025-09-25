extends RichTextLabel

@export var world: Node2D

var amt_of_cows_needed
var amt_of_cows

func _ready() -> void:
	amt_of_cows = 0
	if world:
		amt_of_cows_needed = world.get_amt_of_cows_needed()
		update_text()
	
func add_cow() -> void:
	amt_of_cows += 1
	update_text()
	
func lose_cow() -> void:
	amt_of_cows -= 1
	update_text()

func update_text() -> void:
	text = str("Cows: ", amt_of_cows, "/" ,amt_of_cows_needed)
