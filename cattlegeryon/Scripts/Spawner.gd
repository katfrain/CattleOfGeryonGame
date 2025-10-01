extends Node2D

enum spawner_type_enum {
	COW,
	GADFLY
}

@export var spawner_type: spawner_type_enum
@export var max_instances_in_scene: int
@export var timer_interval: float
@export var wave_size: int = 1

@onready var spawn_timer: Timer = $Timer

# GENERAL VARIABLES
var spawn_scene: PackedScene
var world_bounds: TextureRect
var current_in_scene: int
var screen_area: Area2D
var screen_rect: Rect2

# SCENES
var cow_scene: PackedScene = preload("res://Scenes/cow.tscn")
var fly_scene: PackedScene = preload("res://Scenes/gadfly.tscn")


func _ready() -> void:
	world_bounds = get_parent().get_node("World Bounds") as TextureRect
	var player = get_parent().get_node("Player")
	screen_area = player.get_node("Viewport Bounds") as Area2D
		
	match spawner_type:
		spawner_type_enum.COW:
			spawn_scene = cow_scene
		spawner_type_enum.GADFLY:
			spawn_scene = fly_scene
	
	screen_rect = get_area_rect(screen_area)
	current_in_scene = 0
	spawn_timer.wait_time = timer_interval
	spawn_timer.timeout.connect(on_spawn_timer_timeout)
	spawn_timer.start()
	
func on_spawn_timer_timeout():
	if current_in_scene >= max_instances_in_scene:
		return
	
	var pos = get_spawn_position()
	
	for i in range(wave_size):
		if current_in_scene >= max_instances_in_scene: return
		var instance = spawn_scene.instantiate()
		instance.global_position = pos + Vector2(randf_range(3,20), randf_range(3,20))
		instance.z_index = 1
		add_child(instance)
		current_in_scene += 1

func get_spawn_position() -> Vector2:
	for i in range(100):  # safety loop
		screen_rect = get_area_rect(screen_area)
		var pos = Vector2(
			randf_range(world_bounds.position.x, world_bounds.position.x + world_bounds.size.x),
			randf_range(world_bounds.position.y, world_bounds.position.y + world_bounds.size.y)
		)
		if not screen_rect.has_point(pos):
			return pos
	return Vector2(0,0)
	
func remove_from_scene() -> void:
	current_in_scene = max(current_in_scene - 1, 0)
			
func get_area_rect(area: Area2D) -> Rect2:
	var col = area.get_node("CollisionShape2D") as CollisionShape2D
	if col and col.shape is RectangleShape2D:
		var rect_shape = col.shape as RectangleShape2D
		var extents = rect_shape.extents * col.global_scale  # account for scale
		var top_left = col.global_position - extents
		var size = extents * 2
		return Rect2(top_left, size)
	return Rect2()
	
