extends RigidBody2D

enum States {
	IDLE,
	FOLLOWING,
	FLEEING
}

@export var area: Area2D
@export var range: Area2D
@export var max_health = 200.0
@export var speed = 200
@export var idle_speed = 40
@export var sprite: Sprite2D
@export var direction_images: Array[Texture]
@export var health_bar: ProgressBar
@export var debug_text: RichTextLabel
@export var direction_cooldown: Timer
@export var idle_timer: Timer

var state: States
var current_health: float
var player: CharacterBody2D  
var player_area: CollisionShape2D  
var facing_dir: int = 0
var can_turn = true
var cow_layer
var cow_mask
var spawn_point: Vector2
var idle_move = false
var idle_move_target: Vector2
var idle_move_max_distance = 80.0
var colliding: bool = false

var prev_position: Vector2
var effective_velocity: Vector2

func _ready() -> void:
	state = States.IDLE
	current_health = max_health
	add_to_group("cows")
	add_to_group("bodies")
	player = null
	health_bar.value = 100
	prev_position = global_position
	cow_layer = collision_layer
	cow_mask = collision_mask
	spawn_point = global_position
	create_new_idle_move_target()
	idle_move = true
	colliding = false

func _physics_process(delta: float) -> void:
	effective_velocity = (global_position - prev_position) / delta
	prev_position = global_position
	debug_text.text = str(state)
	
	match state:
		States.FLEEING:
			move_fleeing()
		
		States.FOLLOWING:
			var to_cow = global_position - player_area.global_position
			var player_vel = player.velocity
			var push_strength = to_cow.normalized().dot(player_vel.normalized())
			if push_strength > 0.5: # player moving towards cow
				sidestep(player_vel, to_cow)
			else:
				set_visible_layer()
				follow_player()
				
		States.IDLE:
			idle_behaviour()
	if can_turn:
		update_sprite_direction(effective_velocity)
		
	set_new_z_index()
	
func follow_player() -> void:
	var distance = global_position.distance_to(player_area.global_position)
	if distance > 50:
		var direction = (player_area.global_position - global_position).normalized()
		var to_player = direction * speed
		var separation = get_separation() * speed

		linear_velocity = (to_player + separation).limit_length(speed)
	else:
		linear_velocity = Vector2.ZERO
		
func sidestep(player_vel: Vector2, to_cow: Vector2) -> void:
	set_invisible_layer()
	var perp: Vector2
	if to_cow.cross(player_vel) > 0:
		perp = Vector2(player_vel.y, -player_vel.x) # left
	else:
		perp = Vector2(-player_vel.y, player_vel.x) # right
	
	linear_velocity = perp.normalized() * speed
	
func idle_behaviour() -> void:
	debug_text.text = str(idle_move, idle_move_target)
	if idle_move and idle_move_target:
		debug_text.text = "IDLE MOVING"
		# Move toward the target
		var direction = (idle_move_target - global_position).normalized()
		linear_velocity = direction * idle_speed
		
		# Check if reached target or collided
		if global_position.distance_to(idle_move_target) < 5.0 or colliding:
			# Stop moving
			idle_move = false
			linear_velocity = Vector2.ZERO
			
			# Start idle timer with random duration between 2 and 5 seconds
			var wait_time = randf_range(2.0, 5.0)
			idle_timer.start(wait_time)
			debug_text.text = "IDLE TIMER GOING"
	
func idle_timer_timeout() -> void:
	create_new_idle_move_target()
	idle_move = true

func create_new_idle_move_target() -> void:
	var angle = randf() * TAU
	var distance = sqrt(randf()) * idle_move_max_distance
	
	var offset = Vector2(cos(angle), sin(angle)) * distance
	idle_move_target = spawn_point + offset	
	
func update_sprite_direction(vel: Vector2) -> void:
	var direction = update_direction(vel)
	if direction != facing_dir:
		facing_dir = direction
		if facing_dir >= 0 and facing_dir < direction_images.size():
			sprite.texture = direction_images[facing_dir]


func update_direction(vel: Vector2) -> int:
	var direction
	if vel.length() < 10: # Idle
		return 4
	if vel.length() < 30: # Buffer to avoid switching directions if distance is small enough
		return facing_dir  

	# Snap to 4 directions based on quadrants
	if abs(vel.x) > abs(vel.y):
		if vel.x > 0:
			direction = 0  # right
		else:
			direction = 1  # left
	else:
		if vel.y < 0:
			direction = 2  # up
		else:
			direction = 3  # down
	direction_cooldown.start(0.1)
	can_turn = false
	return direction


func _on_range_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") && state == States.IDLE:
		player = body
		player_area = body.feet_area
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
	var spacing = 64
	var separation = Vector2.ZERO
	for body in range.get_overlapping_bodies():
		if body.is_in_group("cows") || body.is_in_group("player"): 
			var push = global_position - body.global_position
			var dist = push.length()
			if dist > 0 and dist < spacing:
				var strength = (spacing - dist) / spacing
				separation += push.normalized() * strength
	return separation
	

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
	set_invisible_layer()
	speed = speed * 1.5
	
func start_following() -> void:
	state = States.FOLLOWING
	
func start_idle() -> void:
	state = States.IDLE
	sprite.texture = direction_images[4]


func _on_direction_cooldown_timeout() -> void:
	can_turn = true
	
func set_new_z_index() -> void:
	var max_world_y = 5000.0
	var min_world_y = 0.0
	var z_range = 4096

	z_index = int((global_position.y / max_world_y) * z_range)
	
func set_invisible_layer() -> void:
	collision_mask = 0
	set_collision_layer_value(2, false)
	set_collision_layer_value(12, true)

func set_visible_layer() -> void:
	collision_layer = cow_layer


func _on_collision_area_entered(area: Area2D) -> void:
	print("cow colliding with: ",area)
	colliding = true


func _on_collision_area_exited(area: Area2D) -> void:
	colliding = false
