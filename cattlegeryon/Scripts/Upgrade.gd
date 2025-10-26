extends Node

class_name Upgrade

enum upgrade_type_enum {
	MULTIPLY,
	ADDITION,
	SUBTRACTION,
	DIVIDE
}

var level = 1
var upgrade_type = upgrade_type_enum.MULTIPLY
var current_value = 0.0
var upgrade_amt: float
var upgrade_name: String
var upgrade_desc: String
var max_upgrades: int 
var upgrade_number: int
var upgrade_icon: CompressedTexture2D

func _init(_upgrade_type: String, _upgrade_icon: CompressedTexture2D, _upgrade_amt: float, _current_value: float, _upgrade_name: String, _level = 0, _upgrade_desc: String = "N/A", _max_upgrades: int = -1):
	level = _level
	upgrade_icon = _upgrade_icon
	upgrade_amt = _upgrade_amt
	current_value = _current_value
	upgrade_name = _upgrade_name
	upgrade_desc = _upgrade_desc
	max_upgrades = _max_upgrades
	upgrade_number = 0
	match _upgrade_type:
		"Multiply":
			upgrade_type = upgrade_type_enum.MULTIPLY
		"Addition":
			upgrade_type = upgrade_type_enum.ADDITION
		"Subtraction":
			upgrade_type = upgrade_type_enum.SUBTRACTION
		"Divide":
			upgrade_type = upgrade_type_enum.DIVIDE
		_:
			printerr("Not a valid upgrade type")
			
func upgrade() -> float:
	level += 1
	upgrade_number += 1
	var old_value = current_value
	match upgrade_type:
		upgrade_type_enum.MULTIPLY:
			current_value *= upgrade_amt
		upgrade_type_enum.ADDITION:
			current_value += upgrade_amt
		upgrade_type_enum.SUBTRACTION:
			if current_value - upgrade_amt >= 0:
				current_value -= upgrade_amt
		upgrade_type_enum.DIVIDE:
			if upgrade_amt != 0:
				current_value /= upgrade_amt
	return current_value
