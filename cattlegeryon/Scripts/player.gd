extends CharacterBody2D

@export var speed = 300
@export var cattle_needed = 15
@export var feet_area: CollisionShape2D

var amt_of_cattle = 0
var head_collision

signal got_cow
signal lost_cow

func _ready() -> void:
	amt_of_cattle = 0
	add_to_group("player")
	add_to_group("bodies")

func get_input():
	var input_direction = Input.get_vector("left", "right", "up", "down")
	if head_collision and input_direction.y < 0:
		input_direction.y = 0
	
	velocity = input_direction * speed

func _physics_process(delta):
	get_input()
	move_and_slide()
	set_new_z_index()
	
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


func _on_head_area_body_entered(body: Node2D) -> void:
	head_collision = true


func _on_head_area_body_exited(body: Node2D) -> void:
	head_collision = false
	
func set_new_z_index() -> void:
	var max_world_y = 5000.0
	var min_world_y = 0.0
	var z_range = 4096

	z_index = int((feet_area.global_position.y / max_world_y) * z_range)
