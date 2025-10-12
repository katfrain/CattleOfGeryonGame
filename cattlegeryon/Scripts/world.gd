extends Node2D

@export var time_to_hold_cows: float = 10.0

var amt_of_cows_needed: int
var current_amt_of_cows: int = 0
var player: CharacterBody2D = null
var win_timer: Timer
var win_timer_text: RichTextLabel
var win_timer_texture: TextureRect
var win_container: PanelContainer
var lose_container: PanelContainer
var pause_container: PanelContainer
var upgrade_container: PanelContainer
var upgrade_slot_1: Upgrade
var upgrade_slot_2: Upgrade
var upgrade_button_1: Button
var upgrade_button_2: Button
var u1_text: RichTextLabel
var u2_text: RichTextLabel

func _ready() -> void:
	player = get_node("Player") as CharacterBody2D
	win_timer = get_node("Win Timer") as Timer
	win_timer_text = get_node("UI/Win Timer Texture/Win Timer Text") as RichTextLabel
	win_timer_texture = get_node("UI/Win Timer Texture") as TextureRect
	win_container = get_node("UI/Win Container") as PanelContainer
	lose_container = get_node("UI/Lose Container") as PanelContainer
	pause_container = get_node("UI/Pause Container") as PanelContainer
	upgrade_container = get_node("UI/Upgrade Container") as PanelContainer
	upgrade_button_1 = get_node("UI/Upgrade Container/Upgrade Menu Texture/Upgrade 1") as Button
	upgrade_button_2 = get_node("UI/Upgrade Container/Upgrade Menu Texture/Upgrade 2") as Button
	u1_text = get_node("UI/Upgrade Container/Upgrade Menu Texture/Upgrade 1/U1 Text") as RichTextLabel
	u2_text = get_node("UI/Upgrade Container/Upgrade Menu Texture/Upgrade 2/U2 Text") as RichTextLabel
		
	win_timer_texture.visible = false
	win_container.visible = false
	lose_container.visible = false
	pause_container.visible = false
	upgrade_container.visible = false
	
	if !player:
		printerr("Player not found!")
	else:
		amt_of_cows_needed = player.get_amt_of_cows_needed()
		
	unpause()

		
func _process(delta: float) -> void:
	if not win_timer.is_stopped():
		win_timer_text.text = str("%.1f" % win_timer.time_left)
	if Input.is_action_just_pressed("Pause") and get_tree().paused == false:
		open_pause_menu()
	elif Input.is_action_just_pressed("Pause") and get_tree().paused == true:
		close_pause_menu()

func add_cow() -> void:
	if not win_timer.is_stopped():
		return
	
	current_amt_of_cows += 1
	
	if current_amt_of_cows >= amt_of_cows_needed:
		win_timer_texture.visible = true
		win_timer.start(time_to_hold_cows)
	
func remove_cow() -> void:
	if not win_timer.is_stopped():
		win_timer_texture.visible = false
		win_timer.stop()
	if current_amt_of_cows > 0:
		current_amt_of_cows -= 1
	if current_amt_of_cows <= 0:
		lose()

func _on_win_timer_timeout() -> void:
	win_timer_texture.visible = false
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
	
func assign_upgrades(upgrade_1: Upgrade, upgrade_2: Upgrade):
	upgrade_slot_1 = upgrade_1
	upgrade_slot_2 = upgrade_2
	u1_text.text = upgrade_1.upgrade_name
	u2_text.text = upgrade_2.upgrade_name
	
func display_upgrade_menu() -> void:
	upgrade_container.visible = true
	pause()
	
func choose_upgrade_1() -> void:
	player.upgrade(upgrade_slot_1)
	upgrade_container.visible = false
	unpause()
	
func choose_upgrade_2() -> void:
	player.upgrade(upgrade_slot_2)
	upgrade_container.visible = false
	unpause()
	
func open_pause_menu() -> void: 
	pause_container.visible = true
	pause()
	
func close_pause_menu() -> void: 
	pause_container.visible = false
	unpause()
	
func exit_game() -> void: 
	get_tree().quit(0)
