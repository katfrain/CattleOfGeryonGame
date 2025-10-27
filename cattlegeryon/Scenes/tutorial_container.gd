extends Control

@export var tutorials: Array[PanelContainer]
signal close_tutorial_signal
	
func close_tutorial() -> void:
	visible = false
	close_tutorial_signal.emit()
	
func slide1_to_2() -> void:
	tutorials[0].visible = false
	tutorials[1].visible = true
	
func slide2_to_1() -> void:
	tutorials[1].visible = false
	tutorials[0].visible = true
	
func slide2_to_3() -> void:
	tutorials[1].visible = false
	tutorials[2].visible = true
	
func slide3_to_2() -> void:
	tutorials[2].visible = false
	tutorials[1].visible = true
