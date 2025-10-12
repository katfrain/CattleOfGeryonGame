extends CharacterBody2D

@export var speed = 300
@export var cattle_needed = 15
@export var cooldown: float = 3.0
@export var damage_amt: float = 35.0
@export var ultimate_damage: float = 10.0
@export var poison_tick_interval: float = 1.0
@export var poison_ticks: int = 5
@export var level_increase: float = 1.2
@export var ultimate_progress_bar: TextureProgressBar
@export var level_progress_bar: TextureProgressBar
@export var level_text: RichTextLabel
@export var world: Node2D

@onready var ultimate_scene = preload("res://Scenes/ultimate.tscn")
@onready var attack_scene = preload("res://Scenes/attack.tscn")

const ULTIMATE_CHARGE_NEEDED: float = 100.0

var feet_area: CollisionShape2D
var attack_range: Area2D
var ultimate_outer: Area2D
var ultimate_inner: Area2D

var body_sprite: AnimatedSprite2D
var attack_instance
var ultimate_instance
var debug_text: RichTextLabel

var amt_of_cattle = 0
var attack_time: float = 0.3
var input_direction: Vector2
var current_direction: int = 0
var current_ultimate_charge: float = 0.0
var current_level: int = 1
var current_xp = 0
var xp_needed = 100
var attack_transform: Vector2

var head_collision: bool
var cooling_down: bool = false
var attacking: bool = false
var ultimate_ready: bool = false
var moving = false

var cooldown_timer: Timer
var attack_timer: Timer
var ultimate_timer: Timer

# Upgrades
var player_speed_upgrade: Upgrade
var attack_speed_upgrade: Upgrade
var attack_damage_upgrade: Upgrade
var ultimate_damage_upgrade: Upgrade

var upgrades: Array[Upgrade]
var cows: Array[CharacterBody2D]

# Signals
signal got_cow
signal lost_cow

func _ready() -> void:
	feet_area = get_node("Feet") as CollisionShape2D
	attack_range = get_node("Attack Sprite/Attack Range") as Area2D
	ultimate_outer = get_node("Ultimate Sprite/Ultimate range") as Area2D
	ultimate_inner = get_node("Ultimate Sprite/Ultimate inner circle") as Area2D
	body_sprite = get_node("AnimatedSprite2D") as AnimatedSprite2D
	cooldown_timer = get_node("Cooldown Timer") as Timer
	attack_timer = get_node("Attack Timer") as Timer
	ultimate_timer = get_node("Ultimate Timer") as Timer
	debug_text = get_node("DEBUG TEXT") as RichTextLabel

	add_to_group("player")
	add_to_group("bodies")
	
	update_xp_bar()
	
	# General set-up
	amt_of_cattle = 0
	#ultimate_sprite.visible = false
	z_index = 4096
	
	# Create upgrades
	player_speed_upgrade = Upgrade.new("Multiply", 1.1, speed, "Speed", 1, "[color=#7BEA7B]+10%[/color] Speed for Hercules and any following cattle")
	attack_speed_upgrade = Upgrade.new("Multiply", 0.9, cooldown, "Attack Speed", 1, "[color=#F07575]-10%[/color] Time between Auto Attacks")
	attack_damage_upgrade = Upgrade.new("Multiply", 1.2, damage_amt, "Attack Damage", 1, "[color=#7BEA7B]+20%[/color] Attack Damage for Auto Attacks")
	ultimate_damage_upgrade = Upgrade.new("Multiply", 1.2, ultimate_damage, "Ultimate Damage", 1, "[color=#7BEA7B]+20%[/color] Attack Damage for Ultimate")	
	upgrades.append(player_speed_upgrade)
	upgrades.append(attack_speed_upgrade)
	upgrades.append(attack_damage_upgrade)
	upgrades.append(ultimate_damage_upgrade)
	
	body_sprite.play("Idle")
	
# ----------- MOVEMENT FUNCTIONS -------------------

func get_input():
	input_direction = Input.get_vector("left", "right", "up", "down")
	if head_collision and input_direction.y < 0:
		input_direction.y = 0
	
	if Input.is_action_just_pressed("Ultimate") and ultimate_ready: # <-- map this action in InputMap
		play_ultimate_animation()
	
	get_direction()
	adjust_direction()
	velocity = input_direction * speed
	

func _physics_process(delta):
	if not cooling_down:
		play_attack_animation()
		
	if moving and velocity == Vector2.ZERO:
		body_sprite.play("Idle")
		moving = false

	if not moving and velocity != Vector2.ZERO:
		body_sprite.play("Walk")
		moving = true
		
	get_input()
	move_and_slide()
	set_new_z_index()
	
	if attack_instance:
		attack_instance.global_position = global_position
	
	debug_text.text = str(speed)
	
func adjust_direction() -> void:
	match current_direction:
		0: 
			body_sprite.flip_h = true
		1: 
			body_sprite.flip_h = false
			
func get_direction() -> void:
	if input_direction == Vector2.ZERO:
		return # No input, don't change direction
		# Determine dominant axis
	if abs(input_direction.x) > abs(input_direction.y):
		# Horizontal movement
		if input_direction.x > 0:
			# Moving right
			current_direction = 0
		else:
			# Moving left
			current_direction = 1
	else:
		# Vertical movement
		if input_direction.y < 0:
			# Moving up
			current_direction = 2
		else:
			# Moving down
			current_direction = 3
	
	
# ----------- CATTLE FUNCTIONS -------------------
	
func _add_cattle(cow: CharacterBody2D) -> int:
	amt_of_cattle += 1
	got_cow.emit()
	cows.append(cow)
	if amt_of_cattle >= cattle_needed:
		_cattle_amt_reached()
	return cows.size() - 1
		
func lose_cattle(cow_index: int) -> void:
	amt_of_cattle -= 1
	lost_cow.emit()
	cows[cow_index] = null
		
func _cattle_amt_reached() -> void:
	pass

# ----------- ATTACK FUNCTIONS -------------------

func attack() -> void:
	var instance_range = attack_instance.get_node("Attack Range") as Area2D
	for body in instance_range.get_overlapping_bodies():
		if body.is_in_group("gadflies"):
			body.take_damage(damage_amt, true, self)
	attacking = true
	cooling_down = true
	attack_timer.start(attack_time)
	cooldown_timer.start(cooldown)
	
func activate_ultimate() -> void:
	var instance_outer = ultimate_instance.get_node("Ultimate range") as Area2D
	var instance_inner = ultimate_instance.get_node("Ultimate inner circle") as Area2D
	var outer_bodies = instance_outer.get_overlapping_bodies()
	var inner_bodies = instance_inner.get_overlapping_bodies()

	for body in outer_bodies:
		if not body.is_in_group("enemies"): 
			continue
		if inner_bodies.has(body): 
			continue # skip enemies in the safe inner circle

		if body.has_method("apply_poison"):
			body.apply_poison(ultimate_damage, poison_tick_interval, poison_ticks)
			
	current_ultimate_charge = 0
	ultimate_progress_bar.value = 0
	ultimate_ready = false
	
func charge_ultimate(amt: float) -> void:
	current_ultimate_charge = min(current_ultimate_charge + amt, 100)
	if (current_ultimate_charge >= ULTIMATE_CHARGE_NEEDED):
		ultimate_ready = true
	ultimate_progress_bar.value = current_ultimate_charge
	

# ----------- AREA FUNCTIONS -------------------

func _on_head_area_body_entered(body: Node2D) -> void:
	head_collision = true


func _on_head_area_body_exited(body: Node2D) -> void:
	head_collision = false
	
# ----------- Z-INDEX / LAYER FUNCTIONS -------------------

func set_new_z_index() -> void:
	var max_world_y = 5000.0
	var min_world_y = 0.0
	var z_range = 4050

	z_index = int((feet_area.global_position.y / max_world_y) * z_range)


func _on_cooldown_timer_timeout() -> void:
	cooling_down = false


func _on_attack_timer_timeout() -> void:
	attacking = false

	
# ----------- XP / LEVELING FUNCTIONS -------------------

func add_xp(amt: int) -> void:
	current_xp = min(current_xp + amt, xp_needed)
	if (current_xp >= xp_needed):
		level_up()
	update_xp_bar()
	
func level_up() -> void:
	current_level += 1
	xp_needed *= level_increase
	current_xp = 0
	choose_upgrade()
	
func update_xp_bar() -> void:
	level_progress_bar.value = float(current_xp) / float(xp_needed) * 100.0
	level_text.text = str("Level: ", current_level)
	
# ----------- UPGRADE LOGIC -------------------
func choose_upgrade() -> void:
	var i = randi_range(0, upgrades.size() - 1)
	var j = i
	while i == j:
		j = randi_range(0, upgrades.size() - 1)
	world.assign_upgrades(upgrades[i], upgrades[j])
	world.display_upgrade_menu()

func upgrade(upgrade: Upgrade) -> void:
	var value_to_upgrade: float
	match upgrade.upgrade_name:
		"Speed":
			speed = upgrade.upgrade()
			cow_manager.upgrade_cow_speed(upgrade.upgrade_amt)
		"Attack Speed":
			cooldown = upgrade.upgrade()
		"Attack Damage":
			damage_amt = upgrade.upgrade()
		"Ultimate Damage":
			ultimate_damage = upgrade.upgrade()
		_:
			printerr("Invalid upgrade!")
			

# ----------- GETTERS -------------------
func get_amt_of_cows_needed() -> int:
	return cattle_needed
	
# Animation

func play_attack_animation() -> void:
	cooling_down = true
	attack_instance = attack_scene.instantiate()
	attack_instance.frame_changed.connect(_on_attack_frame_changed)
	attack_instance.animation_finished.connect(hide_attack_animation)
	
	adjust_attack_direction()
	
	# Place it at the player's *current* world position

	
	# Add it to the same parent as the player (the world or main scene)
	get_parent().add_child(attack_instance)
	
	# Play the animation (if it doesn’t auto-play)
	attack_instance.play()
	
func play_ultimate_animation() -> void:
	ultimate_instance = ultimate_scene.instantiate()
	ultimate_instance.frame_changed.connect(_on_ultimate_frame_changed)
	ultimate_instance.animation_finished.connect(hide_ultimate_animation)
	
	# Place it at the player's *current* world position
	ultimate_instance.global_position = global_position
	
	# Add it to the same parent as the player (the world or main scene)
	get_parent().add_child(ultimate_instance)
	
	# Play the animation (if it doesn’t auto-play)
	ultimate_instance.play()
		
func adjust_attack_direction() -> void:
	var attack_transform = attack_instance.position
	match current_direction:
		0: 
			attack_instance.rotation_degrees = 180
			attack_instance.flip_v = true
		1: 
			attack_instance.rotation_degrees = 0
			attack_instance.flip_v = false
		2: 
			attack_instance.rotation_degrees = 90
			attack_instance.flip_v = false
		3: 
			attack_instance.rotation_degrees = 270
			attack_instance.flip_v = false
			var temp = attack_transform + Vector2(0,20)
			attack_instance.position = temp
	
	
func _on_attack_frame_changed() -> void:
	if attack_instance.frame == 7:
		attack()
	
func _on_ultimate_frame_changed() -> void:
	if ultimate_instance.frame == 2:
		activate_ultimate()
		
func hide_attack_animation() -> void:
	attack_instance.queue_free()
	
func hide_ultimate_animation() -> void:
	ultimate_instance.queue_free()
	
func reroll_lose_cow() -> void:
	var chosen_cow = reroll_choose_cow()
	chosen_cow.take_damage(chosen_cow.max_health)
	
func reroll_choose_cow() -> CharacterBody2D:
	for cow in cows:
		if cow != null and cow.is_in_group("cows"):
			return cow
			
	printerr("Seomthing went wrong, cannot find cow")
	return null
	
