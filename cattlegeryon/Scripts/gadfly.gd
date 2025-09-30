extends RigidBody2D

@export var max_health = 200.0
@export var speed = 200
@export var direction_images: Array[Texture]
@export var cooldown_time: float = 1.0
@export var damage_amt: float = 5.0

# Rendered Visuals
var debug_text: RichTextLabel
var health_bar: ProgressBar
var sprite: Sprite2D

# Areas
var range: Area2D

# Timers
var attack_cooldown: Timer

# Gadfly changing attributes
var current_health: float
var facing_dir: int = 0
var target: RigidBody2D = null

# Array of all current cows
var all_cows: Array[Node]

# Boolean Values
var cooling_down = false

# Signals
signal fly_died

func _ready() -> void:
	range = get_node("Attack Range") as Area2D
	debug_text = get_node("DEBUG TEXT") as RichTextLabel
	health_bar = get_node("Health Bar") as ProgressBar
	sprite = get_node("Gadfly Sprite") as Sprite2D
	attack_cooldown = get_node("Attack Cooldown") as Timer
	
	add_to_group("gadflies")
	add_to_group("enemies")
	
	current_health = max_health
	health_bar.value = 100
	z_index = 4096

func _physics_process(delta: float) -> void:
	debug_text.text = str(z_index)
	
	if target:
		chase_target()
	else:
		linear_velocity = Vector2.ZERO
		target = find_target()
	
func find_target() -> Node:
	var closest: Node = null
	var closest_dist = INF
	for cow in get_tree().get_nodes_in_group("cows"):
		if not cow or not is_instance_valid(cow):
			continue
		if cow.state != 1: # only follow cows in FOLLOWING state
			continue
		var dist = global_position.distance_to(cow.global_position)
		if dist < closest_dist:
			closest = cow
			closest_dist = dist
	return closest 
	
func chase_target() -> void:
	if not target or not is_instance_valid(target):
		target = null
		return
	
	# Check if target ran away / de-spawned
	if not target.is_in_group("cows"):
		target = null
		return
	
	# Move towards target
	var direction = (target.global_position - global_position).normalized()
	var distance = global_position.distance_to(target.global_position)
	var temp = speed + (distance / 200.0) * speed
	var adjusted_speed = clamp(temp, speed, speed * 3)
	debug_text.text = str(adjusted_speed)
	
	if distance > 10:
		var to_target = direction * adjusted_speed
		var separation = get_separation(adjusted_speed) * adjusted_speed
		linear_velocity = linear_velocity.lerp(to_target + separation, 0.2)
	else:
		linear_velocity = Vector2.ZERO
	
	# Attack if target is inside range
	for body in range.get_overlapping_bodies():
		if body == target && not cooling_down:
			cooling_down = true
			attack_cooldown.start()
			attack_target(target)
			return
	
	# Optional: re-check if a closer cow exists mid-chase
	var new_target = find_target()
	if new_target and new_target != target:
		target = new_target

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
		
# ----------- HEALTH FUNCTIONS -------------------
	
func take_damage(damage_amt: float) -> void:
	current_health -= damage_amt
	update_health_bar()
	if current_health <= 0:
		die()
	
func update_health_bar() -> void:
	health_bar.value = (current_health / max_health) * 100
	
func die() -> void:
	print(get_parent())
	if get_parent() and get_parent().has_method("remove_from_scene"):
		get_parent().remove_from_scene()
	queue_free()
