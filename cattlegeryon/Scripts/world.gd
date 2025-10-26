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
var u1_desc: RichTextLabel
var u2_desc: RichTextLabel
var u1_img: TextureRect
var u2_img: TextureRect
var stats: RichTextLabel
var loss_stats: RichTextLabel
var win_stats: RichTextLabel
var reroll_button: TextureButton

# STATS
var player_base_speed
var player_base_damage
var player_base_ultimate_damage
var player_base_attack_cooldown
var cow_base_health

var pause_menu_open: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
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
	u1_desc = get_node("UI/Upgrade Container/Upgrade Menu Texture/Upgrade 1/U1 Text2") as RichTextLabel
	u2_desc = get_node("UI/Upgrade Container/Upgrade Menu Texture/Upgrade 2/U2 Text2") as RichTextLabel
	u1_img = get_node("UI/Upgrade Container/Upgrade Menu Texture/Upgrade 1/U1 Photo") as TextureRect
	u2_img = get_node("UI/Upgrade Container/Upgrade Menu Texture/Upgrade 2/U2 Photo") as TextureRect
	stats = get_node("UI/Upgrade Container/Upgrade Menu Texture/Stats Title/Stats") as RichTextLabel
	loss_stats = get_node("UI/Lose Container/Win Container Texture/Stats Title/Stats") as RichTextLabel
	win_stats = get_node("UI/Win Container/Win Container Texture/Stats Title/Stats") as RichTextLabel
	reroll_button = get_node("UI/Upgrade Container/Upgrade Menu Texture/ReRoll Button") as TextureButton
		
	win_timer_texture.visible = false
	win_container.visible = false
	lose_container.visible = false
	pause_container.visible = false
	upgrade_container.visible = false
	
	if !player:
		printerr("Player not found!")
	else:
		amt_of_cows_needed = player.get_amt_of_cows_needed()
		player_base_attack_cooldown = player.cooldown
		player_base_damage = player.damage_amt
		player_base_speed = player.speed
		player_base_ultimate_damage = player.ultimate_damage
		
	cow_base_health = cow_manager.cow_health
		
	unpause()

		
func _process(delta: float) -> void:
	if not win_timer.is_stopped():
		win_timer_text.text = str("%.1f" % win_timer.time_left)
	if Input.is_action_just_pressed("Pause") and get_tree().paused == false:
		open_pause_menu()
	elif Input.is_action_just_pressed("Pause") and get_tree().paused == true and pause_menu_open == true:
		close_pause_menu()
	if current_amt_of_cows <= 1:
		reroll_button.disabled = true
	else:
		reroll_button.disabled = false

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
	update_stats()
	win_container.visible = true
	
func lose() -> void:
	pause()
	update_stats()
	lose_container.visible = true
	
func pause() -> void:
	get_tree().paused = true
	
func unpause() -> void:
	pause_container.visible = false
	get_tree().paused = false
	
func restart() -> void:
	pause_container.visible = false
	cow_manager.reset_manager()
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
	u1_desc.bbcode_text = upgrade_1.upgrade_desc
	u2_desc.bbcode_text = upgrade_2.upgrade_desc
	u1_img.texture = upgrade_1.upgrade_icon
	u2_img.texture = upgrade_2.upgrade_icon
	
func display_upgrade_menu() -> void:
	update_stats()
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
	pause_menu_open = true
	pause()
	
func close_pause_menu() -> void: 
	pause_container.visible = false
	pause_menu_open = false
	unpause()
	
func exit_game() -> void: 
	get_tree().quit(0)
	
func update_stats() -> void:
	var stats_string = str("Speed: ", player_base_speed, " [color=#7BEA7B](+", player.speed - player_base_speed, ")[/color]\nDamage: ", player_base_damage, " [color=#7BEA7B](+", player.damage_amt - player_base_damage, ")[/color]\nUltimate Damage: ", player_base_ultimate_damage, " [color=#7BEA7B](+", player.ultimate_damage - player_base_ultimate_damage, ")[/color]\nAttack Cooldown: ", player_base_attack_cooldown, " [color=#F07575](-", player.cooldown - player_base_attack_cooldown, ")[/color]\nCow Health: ", cow_base_health, " [color=#7BEA7B](+", cow_manager.cow_health - cow_base_health, ")[/color]")
	stats.bbcode_text = stats_string
	loss_stats.bbcode_text = stats_string
	win_stats.bbcode_text = stats_string
	
func reroll_button_pressed() -> void:
	if current_amt_of_cows > 1:
		player.reroll_lose_cow()
		player.choose_upgrade()
