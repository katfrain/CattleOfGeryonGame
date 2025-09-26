extends Node2D

enum spawner_type_enum {
	COW,
	ENEMY
}

@export var spawner_type: spawner_type_enum

@onready var spawn_timer: Timer = $Timer

# GENERAL VARIABLES
var spawn_scene: PackedScene
var timer_interval: float
var max_in_scene: int
var world_bounds: TextureRect
var current_in_scene: int
var screen_area: Area2D
var screen_rect: Rect2

# COW SETTINGS
var cow_scene: PackedScene = preload("res://Scenes/cow.tscn")
var max_cow_in_scene:int = 1
var cow_timer_interval:float = 1

# ENEMY SETTINGS
var enemy_scene: PackedScene = preload("res://Scenes/cow.tscn")
var max_enemy_in_scene:int = 25
var enemy_timer_interval = 10.0


func _ready() -> void:
	world_bounds = get_parent().get_node("World Bounds") as TextureRect
	var player = get_parent().get_node("Player")
	screen_area = player.get_node("Viewport Bounds") as Area2D
	
	print(world_bounds, ", ", screen_area)
		
	match spawner_type:
		spawner_type_enum.COW:
			spawn_scene = cow_scene
			max_in_scene = max_cow_in_scene
			timer_interval = cow_timer_interval
		spawner_type_enum.ENEMY:
			spawn_scene = enemy_scene
			max_in_scene = max_enemy_in_scene
			timer_interval = enemy_timer_interval
	
	screen_rect = get_area_rect(screen_area)
	print(screen_rect.get_area())
	current_in_scene = 0
	spawn_timer.wait_time = timer_interval
	spawn_timer.timeout.connect(on_spawn_timer_timeout)
	spawn_timer.start()
	
func on_spawn_timer_timeout():
	if current_in_scene >= max_in_scene:
		return
	
	var instance = spawn_scene.instantiate()
	var pos = get_spawn_position()
	instance.global_position = pos
	instance.z_index = 1
	
	add_child(instance)
	current_in_scene += 1
	print("Spawner has spawned ", current_in_scene, " instances")
	print("Cow spawned at position ", pos)
	print("Cow stats: ", instance.scale)

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
	current_in_scene -= 1
			
func get_area_rect(area: Area2D) -> Rect2:
	var col = area.get_node("CollisionShape2D") as CollisionShape2D
	if col and col.shape is RectangleShape2D:
		var rect_shape = col.shape as RectangleShape2D
		var extents = rect_shape.extents * col.global_scale  # account for scale
		var top_left = col.global_position - extents
		var size = extents * 2
		return Rect2(top_left, size)
	return Rect2()
