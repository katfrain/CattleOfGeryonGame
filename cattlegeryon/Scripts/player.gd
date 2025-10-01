extends CharacterBody2D

@export var speed = 300
@export var cattle_needed = 15
@export var cooldown: float = 3.0
@export var damage_amt: float = 35.0

var feet_area: CollisionShape2D
var attack_range: Area2D

var body_sprite: Sprite2D
var attack_sprite: Sprite2D
var debug_text: RichTextLabel

var amt_of_cattle = 0
var attack_time: float = 0.3
var input_direction: Vector2
var current_direction: int = 0

var head_collision: bool
var cooling_down: bool = false
var attacking: bool = false

var cooldown_timer: Timer
var attack_timer: Timer

# Signals
signal got_cow
signal lost_cow

func _ready() -> void:
	feet_area = get_node("Feet") as CollisionShape2D
	attack_range = get_node("Attack Sprite/Attack Range") as Area2D
	attack_sprite = get_node("Attack Sprite") as Sprite2D
	body_sprite = get_node("Sprite2D") as Sprite2D
	cooldown_timer = get_node("Cooldown Timer") as Timer
	attack_timer = get_node("Attack Timer") as Timer
	debug_text = get_node("DEBUG TEXT") as RichTextLabel

	add_to_group("player")
	add_to_group("bodies")
	
	# General set-up
	amt_of_cattle = 0
	attack_sprite.visible = false
	z_index = 4096
	
# ----------- MOVEMENT FUNCTIONS -------------------

func get_input():
	input_direction = Input.get_vector("left", "right", "up", "down")
	if head_collision and input_direction.y < 0:
		input_direction.y = 0
	
	get_direction()
	adjust_direction()
	velocity = input_direction * speed

func _physics_process(delta):
	if not cooling_down:
		attack()
	
	if attacking:
		attack_sprite.visible = true
	else:
		attack_sprite.visible = false
	
	get_input()
	move_and_slide()
	set_new_z_index()
	
	debug_text.text = str(z_index)
	
func adjust_direction() -> void:
	if attacking:
		match current_direction:
			0: 
				body_sprite.flip_h = false
			1: 
				body_sprite.flip_h = true
	else:
		match current_direction:
			0: 
				body_sprite.flip_h = false
				attack_sprite.rotation_degrees = 180
			1: 
				body_sprite.flip_h = true
				attack_sprite.rotation_degrees = 0
			2: attack_sprite.rotation_degrees = 90
			3: attack_sprite.rotation_degrees = 270
			
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
	
func _add_cattle() -> void:
	amt_of_cattle += 1
	got_cow.emit()
	print("Amount of cattle: ", amt_of_cattle)
	if amt_of_cattle >= cattle_needed:
		_cattle_amt_reached()
		
func lose_cattle() -> void:
	amt_of_cattle -= 1
	lost_cow.emit()
	print("Amount of cattle: ", amt_of_cattle)
		
func _cattle_amt_reached() -> void:
	pass

# ----------- ATTACK FUNCTIONS -------------------

func attack() -> void:
	for body in attack_range.get_overlapping_bodies():
		if body.is_in_group("gadflies"):
			body.take_damage(damage_amt, self)
	attacking = true
	cooling_down = true
	attack_timer.start(attack_time)
	cooldown_timer.start(cooldown)
	

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
