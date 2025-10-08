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

func _init(_upgrade_type: String, _upgrade_amt: float, _current_value: float, _upgrade_name: String, _level = 0):
	level = _level
	upgrade_amt = _upgrade_amt
	current_value = _current_value
	upgrade_name = _upgrade_name
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
	print("Upgrading: ", upgrade_name, ", from ", old_value, " to ", current_value)
	return current_value
