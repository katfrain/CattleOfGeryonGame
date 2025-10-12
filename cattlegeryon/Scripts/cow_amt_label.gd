extends RichTextLabel

var player: CharacterBody2D = null

var amt_of_cows_needed
var amt_of_cows

func _ready() -> void:
	player = get_node("../../../Player") as CharacterBody2D
	
	amt_of_cows = 0
	if player:
		amt_of_cows_needed = player.get_amt_of_cows_needed()
		update_text()
	
func add_cow() -> void:
	amt_of_cows += 1
	update_text()
	
func lose_cow() -> void:
	amt_of_cows -= 1
	update_text()

func update_text() -> void:
	text = str(amt_of_cows, "/" ,amt_of_cows_needed)
