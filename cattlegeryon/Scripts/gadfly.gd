extends RigidBody2D

@export var max_health = 200.0
@export var speed = 200
@export var direction_images: Array[Texture]
@export var cooldown_time: float = 1.0
@export var damage_amt: float = 5.0
@export var knockback_amt: float = 0.5
@export var range_of_sight_radius: float = 1000
@export var idle_speed = 50.0
@export var idle_move_max_distance = 50.0

# Rendered Visuals
var debug_text: RichTextLabel
var health_bar: ProgressBar
var sprite: Sprite2D
var health_bar_base_color: Color
var background_stylebox
var fill_stylebox

# Areas
var attack_range: Area2D

# Timers
var attack_cooldown: Timer
var knockback_cooldown: Timer
var idle_timer: Timer
var poison_dmg_timer: Timer

# Gadfly changing attributes
var current_health: float
var facing_dir: int = 0
var target: RigidBody2D = null
var idle_move_target: Vector2
var idle_initial_pos: Vector2

# Variables to track poison state
var poisoned: bool = false
var poison_damage: float = 0.0
var poison_ticks_remaining: int = 0
var poison_interval: float = 0.0

# Array of all current cows
var all_cows: Array[Node]

# Boolean Values
var cooling_down = false
var knockback = false
var moving: bool = false
var idle_move = false
var colliding: bool = false

var player: Node

# Signals
signal fly_died

func _ready() -> void:
	attack_range = get_node("Attack Range") as Area2D
	debug_text = get_node("DEBUG TEXT") as RichTextLabel
	health_bar = get_node("Health Bar") as ProgressBar
	sprite = get_node("Gadfly Sprite") as Sprite2D
	attack_cooldown = get_node("Attack Cooldown") as Timer
	knockback_cooldown = get_node("Knockback Cooldown") as Timer
	idle_timer = get_node("Idle Timer") as Timer
	poison_dmg_timer = get_node("Poison Damage Timer") as Timer
	
	background_stylebox = health_bar.get("theme_override_styles/background")
	fill_stylebox = health_bar.get("theme_override_styles/fill")
			
	add_to_group("gadflies")
	add_to_group("enemies")
	
	if fill_stylebox is StyleBoxFlat:
		fill_stylebox = fill_stylebox.duplicate()
		health_bar.add_theme_stylebox_override("fill", fill_stylebox)
		health_bar_base_color = fill_stylebox.bg_color
	current_health = max_health
	health_bar.value = 100
	z_index = 4096
	
	idle_initial_pos = global_position
	create_new_idle_move_target()
	idle_move = true
	colliding = false

func _physics_process(delta: float) -> void:
	if !knockback:
		if target:
			debug_text.text = "Chasing!"
			var distance = global_position.distance_to(target.global_position)
			chase_target(distance)
			if distance > range_of_sight_radius: 
				target = null
		else:
			debug_text.text = "Idle!"
			if moving:
				stop_moving()
			idle_behaviour()
			target = find_target()
	
func find_target() -> Node:
	var closest: Node = null
	var closest_dist = INF
	for cow in get_tree().get_nodes_in_group("cows"):
		var dist = global_position.distance_to(cow.global_position)
		if not cow or not is_instance_valid(cow) or cow.state != 1 or dist > range_of_sight_radius:
			continue
		if dist < closest_dist:
			closest = cow
			closest_dist = dist
	return closest 
	
func chase_target(distance: float) -> void:
	if not target or not is_instance_valid(target):
		target = null
		return
	
	# Check if target ran away / de-spawned
	if not target.is_in_group("cows"):
		target = null
		return
	
	# Move towards target
	var direction = (target.global_position - global_position).normalized()
	var temp = speed + (distance / 200.0) * speed
	var adjusted_speed = clamp(temp, speed, speed * 3)
	
	if distance > 50:
		if !moving:
			start_moving()
		var to_target = direction * adjusted_speed
		var separation = get_separation(adjusted_speed) * adjusted_speed
		linear_velocity = linear_velocity.lerp(to_target + separation, 0.2)
	else:
		if moving:
			stop_moving()
		idle_behaviour()
	
	# Attack if target is inside range
	for body in attack_range.get_overlapping_bodies():
		if body == target && not cooling_down:
			cooling_down = true
			attack_cooldown.start()
			attack_target(target)
			return
	
	# Optional: re-check if a closer cow exists mid-chase
	var new_target = find_target()
	if new_target and new_target != target:
		target = new_target
		
func idle_behaviour() -> void:
	if idle_move and idle_move_target:
		# Move toward the target
		var direction = (idle_move_target - global_position).normalized()
		linear_velocity = direction * idle_speed
		
		# Check if reached target or collided
		if global_position.distance_to(idle_move_target) < 5.0 or colliding:
			# Stop moving
			idle_move = false
			linear_velocity = Vector2.ZERO
			# Start idle timer with random duration between 2 and 5 seconds
			var wait_time = randf_range(0.2, 1)
			idle_timer.start(wait_time)
	
func idle_timer_timeout() -> void:
	create_new_idle_move_target()
	idle_move = true

func create_new_idle_move_target() -> void:
	var angle = randf() * TAU
	var distance = sqrt(randf()) * idle_move_max_distance
	
	var offset = Vector2(cos(angle), sin(angle)) * distance
	idle_move_target = idle_initial_pos + offset

func _on_attack_cooldown_timeout() -> void:
	cooling_down = false

func get_separation(a_speed: float):
	var spacing = 64
	var separation = Vector2.ZERO
	for fly in get_tree().get_nodes_in_group("gadflies"):
		if fly == self:
			continue
		var push = global_position - fly.global_position
		var dist = push.length()
		if dist < spacing:
			var strength = (spacing - dist) / spacing
			separation += push.normalized() * strength #* speed
	return separation
	
func attack_target(cow: Node) -> void:
	if cow.has_method("take_damage"):
		cow.take_damage(damage_amt)
		
func stop_moving() -> void:
	idle_initial_pos = global_position
	create_new_idle_move_target()
	moving = false
	
func start_moving() -> void:
	moving = true
		
# ----------- HEALTH FUNCTIONS -------------------
		
func take_damage(damage_amt: float, charges_ultimate: bool, attacker: Node = null) -> void:
	current_health -= damage_amt
	update_health_bar()
	
	if attacker and attacker is Node2D:
		player = attacker
		print("Getting knocked back by: ", attacker)
		var away = (global_position - attacker.global_position).normalized()
		linear_velocity = away * speed * 5
	else:
		# fallback: generic knockback if no attacker passed
		linear_velocity = -linear_velocity.normalized() * speed * 3
	
	knockback = true
	knockback_cooldown.start(knockback_amt)
	
	if current_health <= 0:
		if charges_ultimate and attacker.has_method("charge_ultimate"):
			attacker.charge_ultimate()
		die()
		
func apply_poison(damage_amt: float, interval: float, ticks: int) -> void:
	if poisoned:
		return # Already poisoned

	poisoned = true
	poison_damage = damage_amt
	poison_ticks_remaining = ticks
	poison_interval = interval

	if fill_stylebox is StyleBoxFlat:
		fill_stylebox.bg_color = Color("#5bad7e") 

	poison_dmg_timer.start(poison_interval)
	
func update_health_bar() -> void:
	health_bar.value = (current_health / max_health) * 100
	
func die() -> void:
	print(get_parent())
	if get_parent() and get_parent().has_method("remove_from_scene"):
		get_parent().remove_from_scene()
	queue_free()

func _on_knockback_cooldown_timeout() -> void:
	knockback = false

func _on_poison_damage_timer_timeout() -> void:
	if poison_ticks_remaining > 0:
		take_damage(poison_damage, false, player)
		poison_ticks_remaining -= 1
		poison_dmg_timer.start(poison_interval)
	else:
		if fill_stylebox is StyleBoxFlat:
			fill_stylebox.bg_color = health_bar_base_color
		poison_dmg_timer.stop()
		poisoned = false
