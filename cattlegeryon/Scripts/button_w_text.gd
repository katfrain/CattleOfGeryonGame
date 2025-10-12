extends TextureButton

@onready var text: RichTextLabel = $RichTextLabel
var old_position: Vector2
var new_position: Vector2

func _ready() -> void:
	old_position = text.position
	new_position = old_position + Vector2(0, 2)

func _process(_delta: float) -> void:
	# Keep text down only while button is pressed AND mouse is hovering
	if button_pressed and is_hovered():
		text.position = new_position
	else:
		text.position = old_position
