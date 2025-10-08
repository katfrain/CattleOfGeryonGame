extends Node2D

@export var time_to_hold_cows: float = 10.0

var amt_of_cows_needed: int
var current_amt_of_cows: int = 0
var player: CharacterBody2D = null
var win_timer: Timer
var win_timer_text: RichTextLabel
var win_container: PanelContainer
var lose_container: PanelContainer
var pause_container: PanelContainer

func _ready() -> void:
	player = get_node("Player") as CharacterBody2D
	win_timer = get_node("Win Timer") as Timer
	win_timer_text = get_node("UI/Win Timer Text") as RichTextLabel
	win_container = get_node("UI/Win Container") as PanelContainer
	lose_container = get_node("UI/Lose Container") as PanelContainer
	pause_container = get_node("UI/Pause Container") as PanelContainer
	
	win_timer_text.visible = false
	win_container.visible = false
	lose_container.visible = false
	pause_container.visible = false
	
	if !player:
		printerr("Player not found!")
	else:
		amt_of_cows_needed = player.get_amt_of_cows_needed()
		
	unpause()

		
func _process(delta: float) -> void:
	if not win_timer.is_stopped():
		win_timer_text.text = str("%.1f" % win_timer.time_left)
	if Input.is_action_just_pressed("Pause"):
		pause_container.visible = true
		pause()

func add_cow() -> void:
	if not win_timer.is_stopped():
		return
	
	current_amt_of_cows += 1
	
	if current_amt_of_cows >= amt_of_cows_needed:
		win_timer_text.visible = true
		win_timer.start(time_to_hold_cows)
	
func remove_cow() -> void:
	if not win_timer.is_stopped():
		win_timer_text.visible = false
		win_timer.stop()
	if current_amt_of_cows > 0:
		current_amt_of_cows -= 1
	if current_amt_of_cows <= 0:
		lose()

func _on_win_timer_timeout() -> void:
	win_timer_text.visible = false
	if current_amt_of_cows >= amt_of_cows_needed:
		win()
		
func win() -> void:
	pause()
	win_container.visible = true
	
func lose() -> void:
	pause()
	lose_container.visible = true
	
func pause() -> void:
	get_tree().paused = true
	
func unpause() -> void:
	pause_container.visible = false
	get_tree().paused = false
	
func restart() -> void:
	pause_container.visible = false
	print("attempting to reload scene")
	get_tree().reload_current_scene()
	
func switch_to_main_menu() -> void:
	pause_container.visible = false
	unpause()
	get_tree().change_scene_to_file("res://Scenes/Main Menu.tscn")
