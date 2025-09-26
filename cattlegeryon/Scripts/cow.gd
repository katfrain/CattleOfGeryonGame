extends RigidBody2D

enum States {
	IDLE,
	FOLLOWING,
	FLEEING
}

@export var area: Area2D
@export var max_health = 200.0
@export var speed = 200
@export var sprite: Sprite2D
@export var direction_images: Array[Texture]
@export var health_bar: ProgressBar

var state: States
var current_health: float
var player: CharacterBody2D  
var facing_dir: int = 0

var prev_position: Vector2
var effective_velocity: Vector2

func _ready() -> void:
	state = States.IDLE
	current_health = max_health
	add_to_group("cows")
	player = null
	health_bar.value = 100
	prev_position = global_position

func _physics_process(delta: float) -> void:
	effective_velocity = (global_position - prev_position) / delta
	prev_position = global_position
	
	match state:
		States.FLEEING:
			move_fleeing()
		
		States.FOLLOWING:
			var distance = global_position.distance_to(player.global_position)
			if distance > 24:
				var direction = (player.global_position - global_position).normalized()
				var to_player = direction * speed
				var separation = get_separation() * 200.0
				linear_velocity = (to_player + separation).limit_length(speed)
			else:
				linear_velocity = Vector2.ZERO
	
	update_sprite_direction(effective_velocity)
	


func _on_range_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") && state == States.IDLE:
		player = body
		player._add_cattle()
		start_following()
		


func _on_range_body_exited(body: Node2D) -> void:
	pass

	
func _stop_following_player() -> void:
	pass
	
func _run_away() -> void:
	print("Cow is running away!")
	start_fleeing()
	player.lose_cattle()
	
func take_damage(damage_amt: float) -> void:
	current_health -= damage_amt
	update_health_bar()
	if current_health <= 0:
		_run_away()
	
func get_separation():
	var separation = Vector2.ZERO
	for body in area.get_overlapping_bodies():
		if body.is_in_group("cows"): 
			var push = global_position - body.global_position
			var dist = push.length()
			if dist > 0 and dist < 32: # 32 = desired minimum spacing
				separation += push.normalized() / dist
	return separation
	
func update_sprite_direction(vel: Vector2) -> void:
	if vel.length() < 10:
		sprite.texture = direction_images[4] # idle texture
		return
	
	var direction = update_direction(vel)
	if direction != facing_dir:
		facing_dir = direction
		if facing_dir >= 0 and facing_dir < direction_images.size():
			sprite.texture = direction_images[facing_dir]


func update_direction(vel: Vector2) -> int:
	if vel.length() < 100:
		return facing_dir  

	var angle = vel.angle()

	# Snap to 4 directions based on quadrants
	if abs(vel.x) > abs(vel.y):
		if vel.x > 0:
			return 0  # right
		else:
			return 1  # left
	else:
		if vel.y < 0:
			return 2  # up
		else:
			return 3  # down

func move_fleeing():
	match facing_dir:
		0:  linear_velocity = Vector2.RIGHT * speed
		1:  linear_velocity = Vector2.LEFT * speed
		2:  linear_velocity = Vector2.UP * speed
		3:  linear_velocity = Vector2.DOWN * speed
			
func update_health_bar() -> void:
	health_bar.value = (current_health / max_health) * 100
	
func start_fleeing() -> void:
	state = States.FLEEING
	collision_mask = 0
	set_collision_layer_value(2, false)
	set_collision_layer_value(12, true)
	speed = speed * 1.5
	
func start_following() -> void:
	state = States.FOLLOWING
	
func start_idle() -> void:
	state = States.IDLE
	sprite.texture = direction_images[4]
