extends TextureButton

@onready var text: RichTextLabel = $RichTextLabel
@onready var text2: RichTextLabel = $RichTextLabel2
var old_position1: Vector2
var new_position1: Vector2
var old_position2: Vector2
var new_position2: Vector2

func _ready() -> void:
	old_position1 = text.position
	new_position1 = old_position1 + Vector2(0, 2)
	old_position2 = text2.position
	new_position2 = old_position2 + Vector2(0, 2)

func _process(_delta: float) -> void:
	# Keep text down only while button is pressed AND mouse is hovering
	if (button_pressed and is_hovered()) or disabled:
		text.position = new_position1
		text2.position = new_position2
	else:
		text.position = old_position1
		text2.position = old_position2
