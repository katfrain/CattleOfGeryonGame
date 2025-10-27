extends CharacterBody2D

enum States {
	IDLE,
	FOLLOWING,
	FLEEING
}


@export var idle_speed = 40
@export var idle_move_max_distance = 80.0

@onready var exclamation = $Exclamation

# Rendered Visuals
var debug_text: RichTextLabel
var health_bar: TextureProgressBar
var sprite: AnimatedSprite2D


# Timers
var direction_cooldown: Timer
var idle_timer: Timer

# Areas
var area: Area2D
var range: Area2D
var wall_area: Area2D
var screen_area: Area2D
var screen_rect: Rect2

var nav_agent: NavigationAgent2D

# Cow changing attributes
var state: States
var current_health: float
var facing_dir: int = 0
var idle_move_target: Vector2
var prev_position: Vector2
var effective_velocity: Vector2
var speed: float
var max_health: float

# Cow attributes set at spawn
var cow_layer
var cow_mask
var spawn_point: Vector2

# Boolean Values 
var can_turn = true
var idle_move = false
var colliding: bool = false

# External values
var player: CharacterBody2D  
var player_area: CollisionShape2D  
var player_array_index
var offset

func _ready() -> void:
	area = get_node("Area") as Area2D
	range = get_node("Range") as Area2D
	wall_area = get_node("Wall Area") as Area2D
	sprite = get_node("AnimatedSprite2D") as AnimatedSprite2D
	health_bar = get_node("Health Bar") as TextureProgressBar
	debug_text = get_node("DEBUG TEXT") as RichTextLabel
	direction_cooldown = get_node("Direction Cooldown") as Timer
	idle_timer = get_node("Idle Timer") as Timer
	nav_agent = get_node("NavigationAgent2D") as NavigationAgent2D
		
	add_to_group("cows")
	
	# General set-up
	max_health = cow_manager.cow_health
	current_health = max_health
	player = null
	health_bar.value = 100
	prev_position = global_position
	cow_layer = collision_layer
	cow_mask = collision_mask
	spawn_point = global_position
	
	# Setting up initial idle state
	state = States.IDLE
	create_new_idle_move_target()
	idle_move = true
	colliding = false
	
	sprite.play("Idle")
	
	nav_agent.velocity_computed.connect(on_nav_agent_velocity_computed)
	nav_agent.navigation_finished.connect(on_nav_finished)
	offset = Vector2(randf_range(-8,8), randf_range(-8,8))
	
	exclamation.visible = false
	
	
# ----------- MOVEMENT FUNCTIONS -------------------

func _physics_process(delta: float) -> void:
	if max_health != cow_manager.cow_health:
		max_health = cow_manager.cow_health
		update_health_bar()
		if (state != States.FOLLOWING and state != States.FLEEING):
			heal(max_health)
	speed = cow_manager.cow_speed

	match state:
		States.FLEEING:
			fleeing_behaviour()
		States.FOLLOWING:
			following_behaviour()
		States.IDLE:
			idle_behaviour()
		
	effective_velocity = (global_position - prev_position) / delta
	prev_position = global_position
		
	if nav_agent.is_navigation_finished():
		nav_agent.velocity = Vector2.ZERO
	move_and_slide()
	set_new_z_index()
	update_sprite_direction(effective_velocity)
	
	debug_text.text = str(current_health, "/", max_health)
	

# -- Nav Agent Functions:
func on_nav_finished() -> void:
	pass

func on_nav_agent_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = velocity.move_toward(safe_velocity, speed)
	move_and_slide()
	
func make_path(target: Vector2) -> void:
	if nav_agent.is_navigation_finished() or nav_agent.target_position != target:
		nav_agent.target_position = target

# -- FLEEING functions

func fleeing_behaviour():
	match facing_dir:
		0:  make_path(global_position + Vector2(2000, 0))
		1:  make_path(global_position - Vector2(2000, 0))
		2:  make_path(global_position - Vector2(0, 2000))
		3:  make_path(global_position + Vector2(0, 2000))
		4:  make_path(global_position + Vector2(2000, 0))
		
	var next_path_pos = nav_agent.get_next_path_position()
	var direction = global_position.direction_to(next_path_pos)
	nav_agent.velocity = direction * speed
	
	screen_rect = get_area_rect(screen_area)
	if not screen_rect.has_point(global_position):
		queue_free()

# -- FOLLOWING functions

func following_behaviour() -> void:
	follow_player()
	
func follow_player() -> void:
	make_path(player.global_position + offset)
	var next_path_pos = nav_agent.get_next_path_position()
	var direction = global_position.direction_to(next_path_pos)
	nav_agent.velocity = direction * speed
	
	var target_vel = (next_path_pos - global_position).normalized() * speed
	nav_agent.velocity = nav_agent.velocity.move_toward(target_vel, speed)

		

	
# -- IDLE functions
	
func idle_behaviour() -> void:
	if idle_move and idle_move_target:
		make_path(idle_move_target)
		var next_path_pos = nav_agent.get_next_path_position()
		var direction = global_position.direction_to(next_path_pos)
		nav_agent.velocity = direction * idle_speed
		if global_position.distance_to(idle_move_target) <= 60.0:
			idle_move = false
			nav_agent.velocity = Vector2.ZERO
			idle_timer.start(randf_range(2.0, 5.0))
			
	
func idle_timer_timeout() -> void:
	create_new_idle_move_target()
	idle_move = true

func create_new_idle_move_target() -> void:
	var angle = randf() * TAU
	var distance = max(sqrt(randf()) * idle_move_max_distance, 60)
	
	var offset = Vector2(cos(angle), sin(angle)) * distance
	idle_move_target = spawn_point + offset	
	
# -- DIRECTION functions
func update_sprite_direction(vel: Vector2) -> void:
	var direction = update_direction(vel)
	if direction != facing_dir:
		facing_dir = direction
		if facing_dir >= 0:
			match facing_dir:
				0: sprite.play("Walk Right")
				1: sprite.play("Walk Left")
				2: sprite.play("Walk Up")
				3: sprite.play("Walk Down")
				4: sprite.play("Idle")
 


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
	direction_cooldown.start(0.3)
	can_turn = false
	return direction
	
func _on_direction_cooldown_timeout() -> void:
	can_turn = true
	
# ----------- AREA FUNCTIONS -------------------

func _on_range_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") && state == States.IDLE:
		player = body
		player_area = body.feet_area
		player_array_index = player._add_cattle(self)
		start_following()
func _on_range_body_exited(body: Node2D) -> void:
	pass	
		
func _on_collision_area_entered(area: Area2D) -> void:
	colliding = true

func _on_collision_area_exited(area: Area2D) -> void:
	colliding = false
	
func get_area_rect(area: Area2D) -> Rect2:
	var col = area.get_node("CollisionShape2D") as CollisionShape2D
	if col and col.shape is RectangleShape2D:
		var rect_shape = col.shape as RectangleShape2D
		var extents = rect_shape.extents * col.global_scale  # account for scale
		var top_left = col.global_position - extents
		var size = extents * 2
		return Rect2(top_left, size)
	return Rect2()
	
# ----------- HEALTH FUNCTIONS -------------------
	
func take_damage(damage_amt: float) -> void:
	$AudioStreamPlayer2D.play()
	current_health -= damage_amt
	update_health_bar()
	damage_color()
	if current_health <= 0:
		$AudioStreamPlayer2D2.play()
		start_fleeing()
		
		
func heal(heal_amt: float) -> void:
	current_health += min(heal_amt, max_health - current_health)
	update_health_bar()
	heal_color()
	
func update_health_bar() -> void:
	health_bar.value = (current_health / max_health) * 100
	
func damage_color() -> void:
	var flash_color := Color(1, 0.3, 0.3) # light red
	var normal_color := Color(1, 1, 1)    # default (white)
	
	sprite.modulate = flash_color
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", normal_color, 0.3)
	
func heal_color() -> void:
	var flash_color := Color(0.639, 0.478, 0.639)
	var normal_color := Color(1, 1, 1)    # default (white)
	
	sprite.modulate = flash_color
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", normal_color, 0.3)
	
# ----------- STATE FUNCTIONS -------------------
	
func start_fleeing() -> void:
	remove_from_group("cows")
	state = States.FLEEING
	screen_area = player.get_node("Viewport Bounds") as Area2D
	set_invisible_layer()
	speed = speed * 1.5
	player.lose_cattle(player_array_index)
	if get_parent() and get_parent().has_method("remove_from_scene"):
		get_parent().remove_from_scene()
	
func start_following() -> void:
	state = States.FOLLOWING
	exclamation.visible = true
	$AudioStreamPlayer2D3.play()
	exclamation.play()
	await exclamation.animation_finished
	exclamation.visible = false
	
func start_idle() -> void:
	state = States.IDLE

# ----------- Z-INDEX / LAYER FUNCTIONS -------------------

func set_new_z_index() -> void:
	var max_world_y = 5000.0
	var min_world_y = 0.0
	var z_range = 4050
	var new_z = int((global_position.y / max_world_y) * z_range)
	z_index = clamp(new_z, -4096, 4096)
	
func set_invisible_layer() -> void:
	collision_mask = 128
	set_collision_layer_value(2, false)
	set_collision_layer_value(12, true)

func set_visible_layer() -> void:
	collision_layer = cow_layer
	collision_mask = cow_mask

# ----------- DEBUG FUNCTIONS -------------------

func set_debug_text_to_state() -> void:
	match state:
		States.IDLE:
			debug_text.text = "IDLE"
		States.FOLLOWING:
			debug_text.text = "FOLLOWING"
		States.FLEEING:
			debug_text.text = "FLEEING"
