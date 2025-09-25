extends RigidBody2D

@export var area: Area2D
@export var max_health = 200.0
@export var speed = 200
@export var sprite: Sprite2D
@export var direction_images: Array[Texture]
@export var health_bar: ProgressBar

var current_health: float
var player: CharacterBody2D  
var is_following: bool
var facing_dir: int = 0
var is_fleeing: bool = false

func _ready() -> void:
	current_health = max_health
	add_to_group("cows")
	player = null
	health_bar.value = 100

func _physics_process(delta: float) -> void:
	if is_fleeing:
		move_fleeing()
		return
	if player:
		take_damage(0.5)
		var distance = global_position.distance_to(player.global_position)
		if distance > 24:
			var direction = (player.global_position - global_position).normalized()
			var to_player = direction * speed
			var separation = get_separation() * 200.0
			linear_velocity = (to_player + separation).limit_length(speed)
		else:
			linear_velocity = Vector2.ZERO
	update_sprite_direction()
	


func _on_range_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") && !is_following:
		player = body
		player._add_cattle()
		is_following = true


func _on_range_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("Player exited cow range!")

	
func _stop_following_player() -> void:
	pass
	
func _run_away() -> void:
	print("Cow is running away!")
	is_fleeing = true
	collision_mask = 0
	set_collision_layer_value(2, false)
	set_collision_layer_value(12, true)
	speed = speed * 1.5
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
	
func update_sprite_direction() -> void:
	if linear_velocity.length() < 10:
		return
	
	var direction = update_direction()
	facing_dir = direction 
	
	if direction >= 0 and direction < direction_images.size():
		sprite.texture = direction_images[direction]
			

func update_direction() -> int:

	var angle = linear_velocity.angle()
	
	# Decide which axis dominates
	if abs(linear_velocity.x) > abs(linear_velocity.y):
		# horizontal
		if linear_velocity.x > 0:
			return 0
		else:
			return 1
	else:
		# vertical
		if linear_velocity.y < 0:
			return 2
		else:
			return 3
			
func move_fleeing():
	match facing_dir:
		0:  # right
			linear_velocity = Vector2.RIGHT * speed
		1:  # left
			linear_velocity = Vector2.LEFT * speed
		2:  # up
			linear_velocity = Vector2.UP * speed
		3:  # down
			linear_velocity = Vector2.DOWN * speed
			
func update_health_bar() -> void:
	health_bar.value = (current_health / max_health) * 100
