extends Node2D

@export var base_speed: float = 50.0
@export var max_speed: float = 300.0
@export var acceleration: float = 300.0
@export var deceleration: float = 200.0
@export var xp_amount: int = 10

var player: Node2D = null
var velocity: Vector2 = Vector2.ZERO
var picked_up = false

@onready var pickup_range: Area2D = $"Pickup Range"
@onready var pickup_area: Area2D = $"Pickup Area"

func _ready() -> void:
	pickup_range.body_entered.connect(_on_body_entered)
	pickup_range.body_exited.connect(_on_body_exited)
	pickup_area.body_entered.connect(_on_pickup_area_body_entered)
	
func _physics_process(delta: float) -> void:
	if player:
		var direction = (player.feet_area.global_position - global_position).normalized()
		var desired_velocity = direction * max_speed
		velocity = velocity.move_toward(desired_velocity, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, deceleration * delta)

	global_position += velocity * delta
	
func set_xp_amount(amt: int) -> void:
	xp_amount = amt

func _on_pickup_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("add_xp") and not picked_up:
		body.add_xp(xp_amount)
		var audio = $AudioStreamPlayer2D
		audio.play()
		visible = false
		picked_up = true
		await audio.finished
		queue_free()
		

func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		player = body


func _on_body_exited(body: Node) -> void:
	if body == player:
		player = null
